//
//  StoreError.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

/// Store errors.
enum StoreError: Error {
    /// No RecordDescription for record.
    case missingRecordDescription
    
    /// Preperty is in RecordDescription but not in a struct.
    case propertyMissing
}
