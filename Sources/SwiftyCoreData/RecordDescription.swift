//
//  RecordDescription.swift
//  
//
//  Created by Alexander Smyshlaev on 18.12.2021.
//

/// Describes record properties, should be created using result builder.
public struct RecordDescription {
    let fields: [Field]
    
    var id: String {
        primaryField.name
    }
    
    var primaryField: Field {
        // Already verified primary field in init
        fields.first(where: \.isPrimaryKey)!
    }
    
    var hasTransformableFields: Bool {
        fields.contains { $0.type == .transformable }
    }
    
    private init(fields: [Field]) {
        guard fields.reduce(0, { $0 + ($1.isPrimaryKey ? 1 : 0) }) == 1 else {
            Utils.log("RecordDescription must cointain exactly 1 primary field", level: .error)
            fatalError()
        }
        
        self.fields = fields
    }
    
    func field(for name: String) -> Field? {
        fields.first { $0.name == name }
    }
}

extension RecordDescription {
    @resultBuilder
    public enum ResultBuilder {
        public static func buildExpression(_ expression: Field) -> [Field] {
            [expression]
        }
        
        public static func buildBlock(_ components: Field...) -> [Field] {
            components
        }

        public static func buildBlock(_ components: [Field]) -> [Field] {
            components
        }
        
        public static func buildBlock(_ components: [Field]...) -> [Field] {
            components.flatMap { $0 }
        }
        
        public static func buildOptional(_ component: [Field]?) -> [Field] {
            component ?? []
        }
        
        public static func buildEither(first component: [Field]) -> [Field] {
            component
        }
        
        public static func buildEither(second component: [Field]) -> [Field] {
            component
        }
        
        public static func buildFinalResult(_ component: [Field]) -> RecordDescription {
            RecordDescription(fields: component)
        }
    }
}
