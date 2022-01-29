//
//  SCDEntityDescription.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

public struct SCDEntityDescription {
    public let id: String
    public let fields: [SCDField]
    
    var hasTransformableFields: Bool {
        fields.contains { $0.type == .transformable }
    }
    
    public init(id: String, fields: [SCDField]) {
        self.id = id
        self.fields = fields
    }
    
    func field(for name: String) -> SCDField? {
        fields.first { $0.name == name }
    }
}
