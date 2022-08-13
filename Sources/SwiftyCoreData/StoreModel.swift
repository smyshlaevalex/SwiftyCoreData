//
//  StoreModel.swift
//  
//
//  Created by Alexander Smyshlaev on 03.04.2021.
//

import CoreData

/// Contains current model version and all ``Record`` types used.
public struct StoreModel {
    let version: Int
    let records: [Record.Type]
    
    /// Creates `StoreModel` with current version and ``Record`` types.
    /// - Parameters:
    ///   - version: Current version of the model.
    ///   - records: ``Record`` types used with the model.
    public init(version: Int = 0, records: [Record.Type]) {
        self.version = version
        self.records = records
    }
    
    func makeManagedObjectModel(for version: Int) -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        for record in records {
            let nsEntityDescription = NSEntityDescription()
            nsEntityDescription.name = String(describing: record)
            model.entities.append(nsEntityDescription)
            
            for field in record.recordDescription(for: version).fields {
                let nsAttributeDescription = NSAttributeDescription()
                nsAttributeDescription.name = field.name
                nsAttributeDescription.attributeType = field.type.attributeType
                nsAttributeDescription.isOptional = field.isOptional
                nsAttributeDescription.defaultValue = field.migrationInfo?.default.flatMap(Utils.castToCoreDataValue)
                nsAttributeDescription.renamingIdentifier = field.migrationInfo?.renamingID
                
                nsEntityDescription.properties.append(nsAttributeDescription)
            }
        }
        
        return model
    }
    
    func recordDescription(for type: Record.Type) -> RecordDescription? {
        records.first(where: { $0 == type})?.recordDescription(for: version)
    }
}
