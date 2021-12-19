//
//  SCDError.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

enum SCDError: Error {
    /// No EntityDescription for entity
    case missingEntityDescription
    
    /// Preperty is in EntityDescription but not in a struct
    case propertyMissing
}
