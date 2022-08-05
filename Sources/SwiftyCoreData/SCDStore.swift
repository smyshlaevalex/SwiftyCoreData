//
//  SCDStore.swift
//  
//
//  Created by Alexander Smyshlaev on 29.03.2021.
//

import CoreData

public final class SCDStore {
    private let model: SCDManagedObjectModel
    private let managedObjectContext: NSManagedObjectContext
    
    private var observerToken: NSObjectProtocol?
    
    private var observers: [String: (Notification) -> Void] = [:]
    private var observeHandlers: [String: Any] = [:]
    
    public init(model: SCDManagedObjectModel, type: StoreType = .sqLite, name: String) {
        self.model = model
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model.makeManagedObjectModel())
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let storeUrl = documentsUrl.appendingPathComponent("\(name).sqlite")
        
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = type.type
        persistentStoreDescription.configuration = "Default"
        persistentStoreDescription.url = storeUrl
        
        persistentStoreCoordinator.addPersistentStore(with: persistentStoreDescription) { _, error in
            if let error = error {
                print(error)
            }
        }
        
        observerToken = NotificationCenter.default.addObserver(forName: NSManagedObjectContext.didChangeObjectsNotification,
                                                               object: managedObjectContext,
                                                               queue: .main) { [weak self] notification in
            self?.observers.values.forEach { $0(notification) }
        }
    }
    
    deinit {
        if let observerToken = observerToken {
            NotificationCenter.default.removeObserver(observerToken)
        }
    }
    
    /// Deletes CoreData store
    public func deleteStore() throws {
        guard let store = managedObjectContext.persistentStoreCoordinator?.persistentStores.first,
              let url = store.url else {
            return
        }
        
        try managedObjectContext.persistentStoreCoordinator?.remove(store)
        
        try FileManager.default.removeItem(at: url)
    }
    
    public func save<T: SCDEntity>(entity: T) throws {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        if entityDescription.hasTransformableFields {
            let data = try JSONEncoder().encode(entity)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            try saveAndGetManagedObject(entity: entity, dictionaryRepresentation: dict)
        } else {
            try saveAndGetManagedObject(entity: entity, dictionaryRepresentation: nil)
        }
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type) throws -> [T] {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entityType))
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        
        return try entities(from: managedObjects, entityDescription: entityDescription)
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type, withId id: Any) throws -> T? {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let idName = entityDescription.id
        let idEntityValue = castToCVarArg(id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entityType))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == \(predicateFormatSpecifier(for: idEntityValue))", idEntityValue)
        let managedObject = try managedObjectContext.fetch(fetchRequest).first
        
        return try managedObject.flatMap({ try entities(from: [$0], entityDescription: entityDescription).first })
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type, format: String, arguments: [Any]) throws -> [T] {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entityType))
        fetchRequest.predicate = NSPredicate(format: format, argumentArray: arguments.map(castToCVarArg(_:)))
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        
        return try entities(from: managedObjects, entityDescription: entityDescription)
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type, format: String, _ args: Any...) throws -> [T] {
        try fetch(entityType: entityType, format: format, arguments: args)
    }
    
    public func delete<T: SCDEntity>(entities: [T]) throws {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let idName = entityDescription.id
        
        let ids: [CVarArg] = try entities.map {
            let mirror = Mirror(reflecting: $0)
            guard let idEntityValue = try valueWithName(idName, from: mirror).flatMap(castToCVarArg) else {
                throw SCDError.propertyMissing
            }
            
            return idEntityValue
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "\(idName) IN %@", argumentArray: [ids])
        
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        for managedObject in managedObjects {
            managedObjectContext.delete(managedObject)
        }
    }
    
    public func delete<T: SCDEntity>(entity: T) throws {
        try delete(entities: [entity])
    }
    
    public func commit() throws {
        if managedObjectContext.hasChanges {
            try managedObjectContext.save()
        }
    }
    
    public func observe<T: SCDEntity>(entityType: T.Type, _ observeHandler: @escaping (Changes<T>) -> Void) throws -> Observation {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let entityName = String(describing: T.self)
        
        let id = ProcessInfo.processInfo.globallyUniqueString
        
        observeHandlers[id] = observeHandler
        
        if observers[entityName] == nil {
            observers[entityName] = { [weak self] notification in
                guard let self else { return }
                
                let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
                
                guard let inserted: [T] = try? self.entities(from: Array(insertedObjects), entityDescription: entityDescription, skipOnError: true),
                      let updated: [T] = try? self.entities(from: Array(updatedObjects), entityDescription: entityDescription, skipOnError: true),
                      let deleted: [T] = try? self.entities(from: Array(deletedObjects), entityDescription: entityDescription, skipOnError: true) else {
                    return
                }
                
                let changes = Changes<T>(inserted: inserted, updated: updated, deleted: deleted)
                
                for observeHandler in self.observeHandlers.values {
                    if let observeHandler = observeHandler as? (Changes<T>) -> Void {
                        observeHandler(changes)
                    }
                }
            }
        }
        
        return Observation { [weak self] in
            guard let self else { return }
            
            self.observeHandlers[id] = nil
            
            if !self.observeHandlers.values.contains(where: { $0 is (Changes<T>) -> Void }) {
                self.observers[entityName] = nil
            }
        }
    }
    
    @discardableResult
    private func saveAndGetManagedObject(entity: SCDEntity, dictionaryRepresentation: [String: Any]?) throws -> NSManagedObject  {
        guard let entityDescription = model.entityDescription(for: type(of: entity)),
              let nsEntityDescription = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[String(describing: type(of: entity))] else {
            throw SCDError.missingEntityDescription
        }
        
        let mirror = Mirror(reflecting: entity)
        
        let idName = entityDescription.id
        
        guard let idEntityValue = try valueWithName(idName, from: mirror).flatMap(castToCVarArg) else {
            throw SCDError.propertyMissing
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: type(of: entity)))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == \(predicateFormatSpecifier(for: idEntityValue))", idEntityValue)
        
        let fetchedManagedObject = try managedObjectContext.fetch(fetchRequest).first
        
        let managedObject = fetchedManagedObject ?? NSManagedObject(entity: nsEntityDescription, insertInto: managedObjectContext)
        
        for field in entityDescription.fields {
            managedObject.willChangeValue(forKey: field.name)
            
            let value: Any?
            do {
                if field.type == .transformable,
                   let representation = dictionaryRepresentation?[field.name] {
                    value = try JSONSerialization.data(withJSONObject: representation)
                } else {
                    value = try valueWithName(field.name, from: mirror)
                }
            } catch {
                managedObjectContext.reset()
                throw error
            }
            
            managedObject.setPrimitiveValue(value, forKey: field.name)
            
            managedObject.didChangeValue(forKey: field.name)
        }
        
        return managedObject
    }
    
    private func entities<T: SCDEntity>(from managedObjects: [NSManagedObject], entityDescription: SCDEntityDescription, skipOnError: Bool = false) throws -> [T] {
        if skipOnError {
            return managedObjects.compactMap { managedObject in
                guard let dict = try? entityDictionary(from: managedObject, entityDescription: entityDescription),
                      let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                      let entity = try? JSONDecoder().decode(T.self, from: data) else {
                    return nil
                }
                
                return entity
            }
        } else {
            return try managedObjects.map { managedObject in
                let dict = try entityDictionary(from: managedObject, entityDescription: entityDescription)
                let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                let entity = try JSONDecoder().decode(T.self, from: data)
                
                return entity
            }
        }
    }
    
    private func entityDictionary(from managedObject: NSManagedObject, entityDescription: SCDEntityDescription) throws -> [String: Any] {
        var dict = [String: Any]()
        for field in entityDescription.fields {
            managedObject.willAccessValue(forKey: field.name)
            
            let value = managedObject.primitiveValue(forKey: field.name)
            
            if field.type == .transformable,
                let data = value as? Data {
                dict[field.name] = try JSONSerialization.jsonObject(with: data)
            } else {
                dict[field.name] = value.flatMap(transformToCodable)
            }
            
            managedObject.didAccessValue(forKey: field.name)
        }
        
        return dict
    }
    
    private func valueWithName(_ name: String, from mirror: Mirror) throws -> Any? {
        guard let value = mirror.children.first(where: { $0.label == name })?.value else {
            throw SCDError.propertyMissing
        }
        
        let innerMirror = Mirror(reflecting: value)
        if innerMirror.displayStyle != .optional || !innerMirror.children.isEmpty {
            if let intEnum = value as? SCDIntegerEnum {
                return intEnum.intRawValue
            } else if let stringEnum = value as? SCDStringEnum {
                return stringEnum.stringRawValue
            } else {
                return value
            }
        } else {
            return nil
        }
    }
    
    private func castToCVarArg(_ value: Any) -> CVarArg {
        switch value {
        case is Int: return value as! Int
        case is Double: return value as! Double
        case is String: return value as! String
        case is Bool: return NSNumber(value: value as! Bool)
        case is Date: return value as! NSDate
        case is Data: return value as! NSData
        case is UUID: return value as! NSUUID
        case is URL: return value as! NSURL
        default: fatalError("Value of type \(type(of: value)) can't be casted to CVarArg")
        }
    }
    
    private func transformToCodable(_ value: Any) -> Any {
        switch value {
        case is Int: return value as! Int
        case is Double: return value as! Double
        case is String: return value as! String
        case is Bool: return (value as! NSNumber).boolValue
        case is Date: return (value as! Date).timeIntervalSinceReferenceDate
        case is Data: return (value as! Data).base64EncodedString()
        case is UUID: return (value as! UUID).uuidString
        case is URL: return (value as! URL).absoluteString
        default: fatalError("Value of type \(type(of: value)) can't be casted to Codable compatible")
        }
    }
    
    private func predicateFormatSpecifier(for value: CVarArg) -> String {
        switch value {
        case is Int: return "%i"
        case is Double: return "%f"
        default: return "%@"
        }
    }
}

extension SCDStore {
    public enum StoreType {
        case sqLite
        case inMemory
        
        var type: String {
            switch self {
            case .sqLite: return NSSQLiteStoreType
            case .inMemory: return NSInMemoryStoreType
            }
        }
    }
}
