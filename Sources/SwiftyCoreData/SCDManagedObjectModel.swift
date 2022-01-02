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
                switch field {
                case let attributeField as SCDAttributeField:
                    let nsAttributeDescription = NSAttributeDescription()
                    nsAttributeDescription.name = attributeField.name
                    nsAttributeDescription.attributeType = attributeField.type.attributeType
                    nsAttributeDescription.isOptional = attributeField.isOptional
                    
                    nsEntityDescription.properties.append(nsAttributeDescription)
                    
                case let relationshipField as SCDRelationshipField:
                    let nsRelationshipDescription = NSRelationshipDescription()
                    nsRelationshipDescription.name = relationshipField.name
                    nsRelationshipDescription.isOptional = relationshipField.isOptional
                    nsRelationshipDescription.deleteRule = relationshipField.deleteRule.nsDeleteRule
                    
                    guard let nsDestinationEntityDescription = model.entitiesByName[String(describing: relationshipField.type)] else {
                        fatalError("Couldn't find NSEntityDescription for relationship")
                    }
                    
                    nsRelationshipDescription.destinationEntity = nsDestinationEntityDescription
                    
                    nsRelationshipDescription.minCount = relationshipField.isArray ? 0 : 1
                    nsRelationshipDescription.maxCount = relationshipField.isArray ? 0 : 1
                    
                    nsEntityDescription.properties.append(nsRelationshipDescription)
                    break
                
                default:
                    fatalError("Incompatible SCDField type")
                }
            }
        }
        
        return model
    }
    
    func entityDescription(for type: SCDEntity.Type) -> SCDEntityDescription? {
        entities.first(where: { $0 == type})?.entityDescription
    }
}
