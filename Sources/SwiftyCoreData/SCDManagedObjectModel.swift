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
            model.entities.append(nsEntityDescription)
        }
        
        for entity in entities {
            guard let nsEntityDescription = model.entitiesByName[String(describing: entity)] else {
                fatalError("Couldn't find NSEntityDescription that was just created")
            }
            
            for field in entity.entityDescription.fields {
                let nsAttributeDescription = NSAttributeDescription()
                nsAttributeDescription.name = field.name
                nsAttributeDescription.attributeType = field.type.attributeType
                nsAttributeDescription.isOptional = field.isOptional
                
                nsEntityDescription.properties.append(nsAttributeDescription)
            }
        }
        
        return model
    }
    
    func entityDescription(for type: SCDEntity.Type) -> SCDEntityDescription? {
        entities.first(where: { $0 == type})?.entityDescription
    }
}
