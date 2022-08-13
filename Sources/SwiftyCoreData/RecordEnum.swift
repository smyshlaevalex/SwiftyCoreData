//
//  RecordEnum.swift
//  
//
//  Created by Alexander Smyshlaev on 01.01.2022.
//

/// All ``Int`` enums must conform to this protocol.
public protocol RecordIntegerEnum: Codable {
    var intRawValue: Int { get }
}

/// All ``String`` enums must conform to this protocol.
public protocol RecordStringEnum: Codable {
    var stringRawValue: String { get }
}

public extension RecordIntegerEnum where Self: RawRepresentable, Self.RawValue == Int {
    var intRawValue: Int {
        rawValue
    }
}

public extension RecordStringEnum where Self: RawRepresentable, Self.RawValue == String {
    var stringRawValue: String {
        rawValue
    }
}
