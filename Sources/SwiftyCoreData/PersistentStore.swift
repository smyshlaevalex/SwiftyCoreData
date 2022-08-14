//
//  PersistentStore.swift
//  
//
//  Created by Alexander Smyshlaev on 29.03.2021.
//

import CoreData
import UIKit

/// Object for saving and fetching ``Record`` structs.
public final class PersistentStore {
    private let model: StoreModel
    private let name: String
    private var managedObjectContext: NSManagedObjectContext!
    
    private var didChangeObjectsToken: NSObjectProtocol?
    private var didEnterBackgroundToken: NSObjectProtocol?
    private var willTerminateToken: NSObjectProtocol?
    
    private var observers: [String: (Notification) -> Void] = [:]
    private var observeHandlers: [String: Any] = [:]
    
    /// Observes errors caught when commiting changes to persistent store.
    public var commitChangesErrorObserver: ((Error) -> Void)?
    
    /// Creates PersistentStore with name, type and model.
    /// - Parameters:
    ///   - name: Name of a `PersistentStore`, used as a filename in documents directory.
    ///   - type: ``StoreType`` of a PersistentStore, default is `.sqLite`.
    ///   - model: Model for a PersistentStore.
    public init(name: String = "SwiftyCoreDataStore", type: StoreType = .sqLite, model: StoreModel) {
        self.model = model
        self.name = name
        
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        
        let storeUrl = documentsUrl.appendingPathComponent("\(name).sqlite")
        
        if let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type.type, at: storeUrl) {
            let storeVersion = Self.currentStoreVersion(for: metadata, in: model)
            Utils.log("Current store version: \(storeVersion)")
            if storeVersion < model.version {
                // Require migration
                do {
                    try Self.recursivelyMigrateStore(at: storeUrl, from: storeVersion, to: model.version, storeModel: model, storeType: type)
                } catch {
                    Utils.log("Failed migration", level: .error)
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        let managedObjectModel = model.makeManagedObjectModel(for: model.version)
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = type.type
        persistentStoreDescription.configuration = "Default"
        persistentStoreDescription.url = storeUrl
        persistentStoreDescription.setOption(NSNumber(booleanLiteral: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
        persistentStoreDescription.setOption(NSNumber(booleanLiteral: true), forKey: NSInferMappingModelAutomaticallyOption)
        
        persistentStoreCoordinator.addPersistentStore(with: persistentStoreDescription) { _, error in
            if let error = error {
                Utils.log("Failed to add persistent store", level: .error)
                fatalError(error.localizedDescription)
            }
        }
        
        didChangeObjectsToken = NotificationCenter.default.addObserver(forName: NSManagedObjectContext.didChangeObjectsNotification,
                                                                       object: managedObjectContext,
                                                                       queue: .main) { [weak self] notification in
            self?.observers.values.forEach { $0(notification) }
        }
        
        didEnterBackgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                         object: nil,
                                                                         queue: .main) { [weak self] _ in
            self?.commitChangesIfNeeded()
        }
        
        willTerminateToken = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification,
                                                                    object: nil,
                                                                    queue: .main) { [weak self] _ in
            self?.commitChangesIfNeeded()
        }
    }
    
    deinit {
        if let didChangeObjectsToken = didChangeObjectsToken {
            NotificationCenter.default.removeObserver(didChangeObjectsToken)
        }
        
        if let didEnterBackgroundToken = didEnterBackgroundToken {
            NotificationCenter.default.removeObserver(didEnterBackgroundToken)
        }
        
        if let willTerminateToken = willTerminateToken {
            NotificationCenter.default.removeObserver(willTerminateToken)
        }
    }
    
    /// Deletes CoreData store and all associated files, `PersistentStore` should not be used afterwards.
    public func deleteStore() throws {
        guard let store = managedObjectContext.persistentStoreCoordinator?.persistentStores.first,
              let url = store.url else {
            return
        }
        
        try managedObjectContext.persistentStoreCoordinator?.remove(store)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.removeItem(atPath: url.path.appending("-shm"))
        try FileManager.default.removeItem(atPath: url.path.appending("-wal"))
    }
    
    /// Saves a ``Record`` in a PersistentStore.
    /// - Parameter record: A ``Record`` to be saved.
    public func save<T: Record>(record: T) throws {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        if recordDescription.hasTransformableFields {
            let data = try JSONEncoder().encode(record)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            try saveAndGetManagedObject(record: record, dictionaryRepresentation: dict)
        } else {
            try saveAndGetManagedObject(record: record, dictionaryRepresentation: nil)
        }
    }
    
    /// Fetches all records of provided type.
    /// - Parameter recordType: Type of a ``Record``.
    /// - Returns: Array of records matching provided type.
    public func fetch<T: Record>(recordType: T.Type) throws -> [T] {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: recordType))
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        
        return try makeRecords(from: managedObjects, recordDescription: recordDescription)
    }
    
    /// Fetches a ``Record`` of provided type with provided ID.
    /// - Parameters:
    ///   - recordType: Type of a ``Record``.
    ///   - id: ID of a ``Record``.
    /// - Returns: A ``Record`` matching provided type with provided ID, or nil if such ``Record`` does not exist.
    public func fetch<T: Record>(recordType: T.Type, withId id: Any) throws -> T? {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        let idName = recordDescription.id
        let idRecordValue = Utils.castToCVarArg(id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: recordType))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == \(Utils.predicateFormatSpecifier(for: idRecordValue))", idRecordValue)
        let managedObject = try managedObjectContext.fetch(fetchRequest).first
        
        return try managedObject.flatMap({ try makeRecords(from: [$0], recordDescription: recordDescription).first })
    }
    
    /// Fetches a ``Record`` of provided type using provided predicate.
    /// - Parameters:
    ///   - recordType: Type of a ``Record``.
    ///   - format: The format string of the predicate.
    ///   - arguments: The arguments used with predicate, will be automatically casted to `CVarArg`.
    /// - Returns: Array of records matching provided type and predicate.
    public func fetch<T: Record>(recordType: T.Type, format: String, arguments: [Any]) throws -> [T] {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: recordType))
        fetchRequest.predicate = NSPredicate(format: format, argumentArray: arguments.map(Utils.castToCVarArg(_:)))
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        
        return try makeRecords(from: managedObjects, recordDescription: recordDescription)
    }
    
    /// Fetches a ``Record`` of provided type using provided predicate.
    /// - Parameters:
    ///   - recordType: Type of a ``Record``.
    ///   - format: The format string of the predicate.
    ///   - args: The arguments used with predicate, will be automatically casted to `CVarArg`.
    /// - Returns: Array of records matching provided type and predicate.
    public func fetch<T: Record>(recordType: T.Type, format: String, _ args: Any...) throws -> [T] {
        try fetch(recordType: recordType, format: format, arguments: args)
    }
    
    /// Deletes records from PersistentStore.
    /// - Parameter records: Records to be deleted.
    public func delete<T: Record>(records: [T]) throws {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        let idName = recordDescription.id
        
        let ids: [CVarArg] = try records.map {
            let mirror = Mirror(reflecting: $0)
            guard let idRecordValue = try Utils.valueWithName(idName, from: mirror).flatMap(Utils.castToCVarArg) else {
                throw StoreError.propertyMissing
            }
            
            return idRecordValue
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "\(idName) IN %@", argumentArray: [ids])
        
        let managedObjects = try managedObjectContext.fetch(fetchRequest)
        for managedObject in managedObjects {
            managedObjectContext.delete(managedObject)
        }
    }
    
    /// Deletes a ``Record`` from PersistentStore.
    /// - Parameter record: A ``Record`` to be deleted.
    public func delete<T: Record>(record: T) throws {
        try delete(records: [record])
    }
    
    /// Sets up an observer for objects with provided type.
    /// - Parameters:
    ///   - recordType: Type of a ``Record`` to be observed.
    ///   - observeHandler: Handler will be called with a ``Changes`` object containing changes.
    /// - Returns: ``Observation`` object for canceling observation.
    public func observe<T: Record>(recordType: T.Type, _ observeHandler: @escaping (Changes<T>) -> Void) throws -> Observation {
        guard let recordDescription = model.recordDescription(for: T.self) else {
            throw StoreError.missingRecordDescription
        }
        
        let recordName = String(describing: T.self)
        
        let id = ProcessInfo.processInfo.globallyUniqueString
        
        observeHandlers[id] = observeHandler
        
        if observers[recordName] == nil {
            observers[recordName] = { [weak self] notification in
                guard let sSelf = self else { return }
                
                let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
                
                guard let inserted: [T] = try? sSelf.makeRecords(from: Array(insertedObjects), recordDescription: recordDescription, skipOnError: true),
                      let updated: [T] = try? sSelf.makeRecords(from: Array(updatedObjects), recordDescription: recordDescription, skipOnError: true),
                      let deleted: [T] = try? sSelf.makeRecords(from: Array(deletedObjects), recordDescription: recordDescription, skipOnError: true) else {
                    return
                }
                
                let changes = Changes<T>(inserted: inserted, updated: updated, deleted: deleted)
                
                for observeHandler in sSelf.observeHandlers.values {
                    if let observeHandler = observeHandler as? (Changes<T>) -> Void {
                        observeHandler(changes)
                    }
                }
            }
        }
        
        return Observation { [weak self] in
            guard let sSelf = self else { return }
            
            sSelf.observeHandlers[id] = nil
            
            if !sSelf.observeHandlers.values.contains(where: { $0 is (Changes<T>) -> Void }) {
                sSelf.observers[recordName] = nil
            }
        }
    }
    
    /// Commits changes into CoreData store for persistency if needed.
    public func commitChangesIfNeeded() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                commitChangesErrorObserver?(error)
            }
        }
    }
    
    @discardableResult
    private func saveAndGetManagedObject(record: Record, dictionaryRepresentation: [String: Any]?) throws -> NSManagedObject  {
        guard let recordDescription = model.recordDescription(for: type(of: record)),
              let nsRecordDescription = managedObjectContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[String(describing: type(of: record))] else {
            throw StoreError.missingRecordDescription
        }
        
        let mirror = Mirror(reflecting: record)
        
        let idName = recordDescription.id
        
        guard let idRecordValue = try Utils.valueWithName(idName, from: mirror).flatMap(Utils.castToCVarArg) else {
            throw StoreError.propertyMissing
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: type(of: record)))
        fetchRequest.predicate = NSPredicate(format: "\(idName) == \(Utils.predicateFormatSpecifier(for: idRecordValue))", idRecordValue)
        
        let fetchedManagedObject = try managedObjectContext.fetch(fetchRequest).first
        
        let managedObject = fetchedManagedObject ?? NSManagedObject(entity: nsRecordDescription, insertInto: managedObjectContext)
        
        for field in recordDescription.fields {
            managedObject.willChangeValue(forKey: field.name)
            
            let value: Any?
            do {
                if field.type == .transformable,
                   let representation = dictionaryRepresentation?[field.name] {
                    value = try JSONSerialization.data(withJSONObject: representation)
                } else {
                    value = try Utils.valueWithName(field.name, from: mirror)
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
    
    private func makeRecords<T: Record>(from managedObjects: [NSManagedObject], recordDescription: RecordDescription, skipOnError: Bool = false) throws -> [T] {
        if skipOnError {
            return managedObjects.compactMap { managedObject in
                guard let dict = try? recordDictionary(from: managedObject, recordDescription: recordDescription),
                      let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                      let record = try? JSONDecoder().decode(T.self, from: data) else {
                    return nil
                }
                
                return record
            }
        } else {
            return try managedObjects.map { managedObject in
                let dict = try recordDictionary(from: managedObject, recordDescription: recordDescription)
                let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                let record = try JSONDecoder().decode(T.self, from: data)
                
                return record
            }
        }
    }
    
    private func recordDictionary(from managedObject: NSManagedObject, recordDescription: RecordDescription) throws -> [String: Any] {
        var dict = [String: Any]()
        for field in recordDescription.fields {
            managedObject.willAccessValue(forKey: field.name)
            
            let value = managedObject.primitiveValue(forKey: field.name)
            
            if field.type == .transformable,
                let data = value as? Data {
                dict[field.name] = try JSONSerialization.jsonObject(with: data)
            } else if field.type == .boolean {
                dict[field.name] = value as? Bool
            } else {
                dict[field.name] = value.flatMap(Utils.transformToCodable)
            }
            
            managedObject.didAccessValue(forKey: field.name)
        }
        
        return dict
    }
}

extension PersistentStore {
    private static func currentStoreVersion(for metadata: [String: Any], in model: StoreModel) -> Int {
        let finalVersion = model.version
        
        for version in (0...finalVersion).reversed() {
            if model.makeManagedObjectModel(for: version).isConfiguration(withName: "Default", compatibleWithStoreMetadata: metadata) {
                return version
            }
        }
        
        Utils.log("Every model version is incompatible with metadata", level: .error)
        fatalError()
    }
    
    /// Example: When migrating from version 4 to version 6, it will first migrate to version 5 and then 6
    private static func recursivelyMigrateStore(at storeURL: URL,
                                                from version: Int,
                                                to finalVersion: Int,
                                                storeModel: StoreModel,
                                                storeType: StoreType) throws {
        let nextVersion = version + 1
        
        let sourceMOM = storeModel.makeManagedObjectModel(for: version)
        let destinationMOM = storeModel.makeManagedObjectModel(for: nextVersion)

        let mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceMOM, destinationModel: destinationMOM)
        
        let migrationManager = NSMigrationManager(sourceModel: sourceMOM, destinationModel: destinationMOM)
        try migrationManager.migrateStore(from: storeURL, sourceType: storeType.type, with: mappingModel, toDestinationURL: storeURL, destinationType: storeType.type)
        
        Utils.log("Migrated store to version: \(nextVersion)")
        
        if nextVersion < finalVersion {
            try recursivelyMigrateStore(at: storeURL, from: nextVersion, to: finalVersion, storeModel: storeModel, storeType: storeType)
        }
    }
}

extension PersistentStore {
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
