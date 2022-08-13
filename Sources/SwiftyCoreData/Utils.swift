//
//  Utils.swift
//  
//
//  Created by Alexander Smyshlaev on 11.08.2022.
//

import Foundation

enum Utils {
    static func castToCoreDataValue(_ value: Any) -> Any {
        if let intEnum = value as? RecordIntegerEnum {
            return intEnum.intRawValue
        } else if let stringEnum = value as? RecordStringEnum {
            return stringEnum.stringRawValue
        } else {
            return value
        }
    }
    
    static func valueWithName(_ name: String, from mirror: Mirror) throws -> Any? {
        guard let value = mirror.children.first(where: { $0.label == name })?.value else {
            throw StoreError.propertyMissing
        }
        
        let innerMirror = Mirror(reflecting: value)
        if innerMirror.displayStyle != .optional || !innerMirror.children.isEmpty {
            return castToCoreDataValue(value)
        } else {
            return nil
        }
    }
    
    static func castToCVarArg(_ value: Any) -> CVarArg {
        switch value {
        case is Int: return value as! Int
        case is Double: return value as! Double
        case is String: return value as! String
        case is Bool: return NSNumber(value: value as! Bool)
        case is Date: return value as! NSDate
        case is Data: return value as! NSData
        case is UUID: return value as! NSUUID
        case is URL: return value as! NSURL
        default:
            Utils.log("Value of type \(type(of: value)) can't be casted to CVarArg", level: .error)
            fatalError()
        }
    }
    
    static func transformToCodable(_ value: Any) -> Any {
        switch value {
        case is Int: return value as! Int
        case is Double: return value as! Double
        case is String: return value as! String
        case is Bool: return (value as! NSNumber).boolValue
        case is Date: return (value as! Date).timeIntervalSinceReferenceDate
        case is Data: return (value as! Data).base64EncodedString()
        case is UUID: return (value as! UUID).uuidString
        case is URL: return (value as! URL).absoluteString
        default:
            Utils.log("Value of type \(type(of: value)) can't be casted to Codable compatible", level: .error)
            fatalError()
        }
    }
    
    static func predicateFormatSpecifier(for value: CVarArg) -> String {
        switch value {
        case is Int: return "%i"
        case is Double: return "%f"
        default: return "%@"
        }
    }
}

extension Utils {
    enum LogLevel: String {
        case normal = "🔵"
        case error = "🔴"
    }
    
    static func log(_ message: String, level: LogLevel = .normal) {
        print(level.rawValue, "SCD:", message)
    }
}
