//
//  SCDStoreObservation.swift
//  
//
//  Created by Alexander Smyshlaev on 03.03.2022.
//

extension SCDStore {
    public final class Observation {
        private let removeObserver: () -> Void
        
        init(removeObserver: @escaping () -> Void) {
            self.removeObserver = removeObserver
        }
        
        deinit {
            removeObserver()
        }
        
        public func invalivate() {
            removeObserver()
        }
    }
}
