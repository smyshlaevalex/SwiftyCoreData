//
//  SCDField.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

import CoreData

public struct SCDField {
    let name: String
    let type: FieldType
    let isOptional: Bool
}

extension SCDField {
    public init(name: String, type: FieldType, optional: Bool = false) {
        self.name = name
        self.type = type
        isOptional = optional
    }
}

extension SCDField {
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
