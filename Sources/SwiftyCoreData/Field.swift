//
//  Field.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

import CoreData

/// A representation of a struct property.
public struct Field {
    let isPrimaryKey: Bool
    let name: String
    let type: FieldType
    let isOptional: Bool
    let migrationInfo: MigrationInfo?
}

extension Field {
    /// Creates a field using provided properties.
    /// - Parameters:
    ///   - primaryKey: Whatever a field is a primary key or not. Every ``Record`` should have one primary key.
    ///   - name: Name of a field, must be the same as the referenced property.
    ///   - type: Type of a field, must be the same as the referenced property.
    ///   - optional: Whatever a field is optional or not, if true referenced property must also be optional.
    ///   - migrationInfo: Additional information that is used for lightweight migration.
    public init(primaryKey: Bool = false, name: String, type: FieldType, optional: Bool = false, migrationInfo: MigrationInfo? = nil) {
        isPrimaryKey = primaryKey
        self.name = name
        self.type = type
        isOptional = optional
        self.migrationInfo = migrationInfo
    }
}

extension Field {
    public enum FieldType {
        /// Int type.
        case integer
        /// Double type.
        case double
        /// String type.
        case string
        /// Bool type.
        case boolean
        /// Date type.
        case date
        /// Data type.
        case binaryData
        /// UUID type.
        case uuid
        /// Url type.
        case url
        /// Any type conforming to Codable protocol, can't use predicate with this type.
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

extension Field {
    /// Object that provides information needed for lightweight migration.
    /// - Default value is needed for adding a new property, or changing optional property to non-optional.
    /// - renamingID is needed for renaming a property, must match original name of a property.
    public struct MigrationInfo {
        let `default`: Any?
        let renamingID: String?
        
        /// Creates MigrationInfo with renamingID and without default value.
        /// - Parameter renamingID: Original name of a property
        public init(renamingID: String) {
            self.default = nil
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type Int and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: Int, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type Double and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: Double, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type String and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: String, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type Bool and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: Bool, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type Date and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: Date, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type Data and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: Data, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type UUID and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: UUID, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value of type URL and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init(`default`: URL, renamingID: String? = nil) {
            self.default = `default`
            self.renamingID = renamingID
        }
        
        /// Creates MigrationInfo with default value conforming to Encodable protocol for transformable fields and renamingID.
        /// - Parameters:
        ///   - default: Default value for a property
        ///   - renamingID: Original name of a property
        public init<E: Encodable>(`default`: E, renamingID: String? = nil) {
            self.default = try? JSONEncoder().encode(`default`)
            self.renamingID = renamingID
        }
    }
}
