//
//  PersistentStoreObservation.swift
//  
//
//  Created by Alexander Smyshlaev on 03.03.2022.
//

extension PersistentStore {
    /// Observation will continue as long as this object has stong references, observer will be removed when `Observation` object is deallocated.
    public final class Observation {
        private let removeObserver: () -> Void
        
        init(removeObserver: @escaping () -> Void) {
            self.removeObserver = removeObserver
        }
        
        deinit {
            removeObserver()
        }
    }
}
