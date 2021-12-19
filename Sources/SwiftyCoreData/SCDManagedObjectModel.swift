//
//  SCDManagedObjectModel.swift
//  
//
//  Created by Alexander Smyshlaev on 03.04.2021.
//

import CoreData

public struct SCDManagedObjectModel {
    public let entities: [SCDEntity.Type]
    
    public init(entities: [SCDEntity.Type]) {
        self.entities = entities
    }
    
    func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        for entity in entities {
            let nsEntityDescription = NSEntityDescription()
            nsEntityDescription.name = String(describing: entity)
            
            for field in entity.entityDescription.fields {
                let nsAttributeDescription = NSAttributeDescription()
                nsAttributeDescription.name = field.name
                nsAttributeDescription.attributeType = field.type.attributeType
                nsAttributeDescription.isOptional = field.isOptional
                
                nsEntityDescription.properties.append(nsAttributeDescription)
            }
            
            model.entities.append(nsEntityDescription)
        }
        
        return model
    }
    
    func entityDescription<T: SCDEntity>(for type: T.Type) -> SCDEntityDescription? {
        entities.first(where: { $0 == type})?.entityDescription
    }
}
