//
//  PersistentStoreChanges.swift
//  
//
//  Created by Alexander Smyshlaev on 03.03.2022.
//

extension PersistentStore {
    /// Contains changes for observed ``Record`` type.
    public struct Changes<T: Record> {
        /// Contains all inserted records.
        public let inserted: [T]
        
        /// Contains all updated records.
        public let updated: [T]
        
        /// Contains all deleted records.
        public let deleted: [T]
    }
}
