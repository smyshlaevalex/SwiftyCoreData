//
//  File.swift
//  
//
//  Created by Alexander Smyshlaev on 01.01.2022.
//

public protocol SCDIntegerEnum: Codable {
    var intRawValue: Int { get }
}

public protocol SCDStringEnum: Codable {
    var stringRawValue: String { get }
}

public extension SCDIntegerEnum where Self: RawRepresentable, Self.RawValue == Int {
    var intRawValue: Int {
        rawValue
    }
}

public extension SCDStringEnum where Self: RawRepresentable, Self.RawValue == String {
    var stringRawValue: String {
        rawValue
    }
}
