//
//  SCDEntity.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

public protocol SCDEntity: Codable {
    static var entityDescription: SCDEntityDescription { get }
}
