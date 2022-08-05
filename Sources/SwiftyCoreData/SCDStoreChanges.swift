//
//  SCDStoreChanges.swift
//  
//
//  Created by Alexander Smyshlaev on 03.03.2022.
//

extension SCDStore {
    public struct Changes<T: SCDEntity> {
        public let inserted: [T]
        public let updated: [T]
        public let deleted: [T]
    }
}
