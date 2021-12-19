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
            print(error)
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
        guard let entityDescription = model.entityDescription(for: T.self),
              let nsEntityDescription = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[String(describing: T.self)] else {
            throw SCDError.missingEntityDescription
        }
        
        let mirror = Mirror(reflecting: entity)
        
        let idName = entityDescription.id
        
        guard let idEntityValue = valueWithName(idName, from: mirror).flatMap(castToCVarArg) else {
            throw SCDError.propertyMissing
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == %@", idEntityValue)
        
        let fetchedManagedObject = try managedObjectContext.fetch(fetchRequest).first
        
        let managedObject = fetchedManagedObject ?? NSManagedObject(entity: nsEntityDescription, insertInto: managedObjectContext)
        
        for field in entityDescription.fields {
            managedObject.willChangeValue(forKey: field.name)
            
            guard let value = valueWithName(field.name, from: mirror) else {
                managedObjectContext.reset()
                throw SCDError.propertyMissing
            }
            
            managedObject.setPrimitiveValue(value, forKey: field.name)
            managedObject.didChangeValue(forKey: field.name)
        }
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type) throws -> [T] {
        guard let nsEntityDescription = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[String(describing: entityType)] else {
            throw SCDError.missingEntityDescription
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entityType))
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        
        var entities = [T]()
        for managedObject in managedObjects {
            var dict = [String: Any]()
            for property in nsEntityDescription.properties {
                managedObject.willAccessValue(forKey: property.name)
                
                guard let value = managedObject.primitiveValue(forKey: property.name) else {
                    throw SCDError.propertyMissing
                }
                
                dict[property.name] = transformToCodable(value)
                managedObject.didAccessValue(forKey: property.name)
            }
            
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let entity = try JSONDecoder().decode(T.self, from: data)
            
            entities.append(entity)
        }
        
        return entities
    }
    
    public func fetch<T: SCDEntity>(entityType: T.Type, withId id: Any) throws -> T? {
        guard let entityDescription = model.entityDescription(for: T.self),
              let nsEntityDescription = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[String(describing: T.self)] else {
            throw SCDError.missingEntityDescription
        }
        
        let idName = entityDescription.id
        let idEntityValue = castToCVarArg(id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entityType))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == %@", idEntityValue)
        let fetchedManagedObject = try managedObjectContext.fetch(fetchRequest).first
        
        if let fetchedManagedObject = fetchedManagedObject {
            var dict = [String: Any]()
            for property in nsEntityDescription.properties {
                fetchedManagedObject.willAccessValue(forKey: property.name)
                
                guard let value = fetchedManagedObject.primitiveValue(forKey: property.name) else {
                    throw SCDError.propertyMissing
                }
                
                dict[property.name] = transformToCodable(value)
                fetchedManagedObject.didAccessValue(forKey: property.name)
            }
            
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let entity = try JSONDecoder().decode(T.self, from: data)
            
            return entity
        } else {
            return nil
        }
    }
    
    public func delete<T: SCDEntity>(entities: [T]) throws {
        guard let entityDescription = model.entityDescription(for: T.self) else {
            throw SCDError.missingEntityDescription
        }
        
        let idName = entityDescription.id
        
        let ids: [CVarArg] = try entities.map {
            let mirror = Mirror(reflecting: $0)
            guard let idEntityValue = valueWithName(idName, from: mirror).flatMap(castToCVarArg) else {
                throw SCDError.propertyMissing
            }
            
            return idEntityValue
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "\(idName) IN %@", ids)
        
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
    
    private func valueWithName(_ name: String, from mirror: Mirror) -> Any? {
        mirror.children.first(where: { $0.label == name })?.value
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
