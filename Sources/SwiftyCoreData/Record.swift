//
//  Record.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

/// Protocol providing description for all stored properties, requires conformation to be stored in ``PersistentStore``.
public protocol Record: Codable {
    /// Method provides ``Field`` objects describing `Record` properties using a result builder. Will be called multiple times for each model version.
    /// - Parameter version: Model version.
    /// - Returns: A ``RecordDescription`` object that describes `Record` properties. Must cointain one primary field.
    @RecordDescription.ResultBuilder
    static func recordDescription(for version: Int) -> RecordDescription
}
