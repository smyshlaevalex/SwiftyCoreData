import XCTest
@testable import SwiftyCoreData

struct Tag {
    let id: String
    let name: String
}

extension Tag: SCDEntity {
    static var entityDescription: SCDEntityDescription {
        SCDEntityDescription(id: "id", fields: [
            SCDAttributeField(name: "id", type: .string),
            SCDAttributeField(name: "name", type: .string)
        ])
    }
}

struct Entry {
    let id: String
    let tags: [Tag]
}

extension Entry: SCDEntity {
    static var entityDescription: SCDEntityDescription {
        SCDEntityDescription(id: "id", fields: [
            SCDField(name: "id", type: .string),
            SCDField(name: "tags", type: .transformable)
        ])
    }
}

final class SwiftyCoreDataTests: XCTestCase {
    private var store: SCDStore!
    
    override func setUpWithError() throws {
        store = SCDStore(model: SCDManagedObjectModel(entities: [
            Tag.self, Entry.self
        ]), type: .inMemory, name: "Model")
    }
    
    func testFetchPredicate() throws {
        let aTag = Tag(id: "a", name: "A")
        let bTag = Tag(id: "b", name: "B")
        let cTag = Tag(id: "c", name: "B")
        
        try store.save(entity: aTag)
        try store.save(entity: bTag)
        try store.save(entity: cTag)
        try store.commit()
        
        XCTAssert(try store.fetch(entityType: Tag.self, format: "name == %@", "A").count == 1)
        XCTAssert(try store.fetch(entityType: Tag.self, format: "name == %@", "B").count == 2)
    }
}
