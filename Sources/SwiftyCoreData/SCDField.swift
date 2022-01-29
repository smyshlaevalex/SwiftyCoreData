//
//  SCDField.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

import CoreData

public protocol SCDField {
    var name: String { get }
    var isOptional: Bool { get }
    
    func optional() -> Self
}

public struct SCDAttributeField: SCDField {
    public let name: String
    public let isOptional: Bool
    
    let type: FieldType
}

extension SCDAttributeField {
    public init(name: String, type: FieldType) {
        self.name = name
        self.type = type
        isOptional = false
    }
    
    public func optional() -> SCDAttributeField {
        SCDAttributeField(name: name, isOptional: true, type: type)
    }
}

extension SCDAttributeField {
    public enum FieldType {
        /// Int type
        case integer
        /// Double type
        case double
        /// String type
        case string
        /// Bool type
        case boolean
        /// Date type
        case date
        /// Data type
        case binaryData
        /// UUID type
        case uuid
        /// Url type
        case url
        /// Any type conforming to Codable protocol, can't use predicate with this type
        case transformable
        
        var attributeType: NSAttributeType {
            switch self {
            case .integer: return .integer64AttributeType
            case .double: return .doubleAttributeType
            case .string: return .stringAttributeType
            case .boolean: return .booleanAttributeType
            case .date: return .dateAttributeType
            case .binaryData: return .binaryDataAttributeType
            case .uuid: return .UUIDAttributeType
            case .url: return .URIAttributeType
            case .transformable: return .binaryDataAttributeType
            }
        }
    }
}

public struct SCDRelationshipField: SCDField {
    public let name: String
    public let isOptional: Bool
    
    let isArray: Bool
    let type: SCDEntity.Type
}

extension SCDRelationshipField {
    public init(name: String, type: SCDEntity.Type) {
        self.name = name
        self.type = type
        isOptional = false
        isArray = false
    }
    
    public func optional() -> SCDRelationshipField {
        SCDRelationshipField(name: name, isOptional: true, isArray: isArray, type: type)
    }
    
    public func array() -> SCDRelationshipField {
        SCDRelationshipField(name: name, isOptional: isOptional, isArray: true, type: type)
    }
}
