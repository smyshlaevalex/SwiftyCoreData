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
            SCDAttributeField(name: "id", type: .string),
            SCDRelationshipField(name: "tags", type: Tag.self).array().deleteRule(.noAction)
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
    
    func testNoActionDeleteRule() throws {
        let aTag = Tag(id: "a", name: "A")
        let bTag = Tag(id: "b", name: "B")
        let cTag = Tag(id: "c", name: "C")
        
        try store.save(entity: aTag)
        try store.save(entity: bTag)
        try store.save(entity: cTag)
        try store.commit()
        
        XCTAssert(try store.fetch(entityType: Tag.self).count == 3)
        
        let entry = Entry(id: "entry", tags: [aTag, bTag])
        try store.save(entity: entry)
        try store.delete(entity: entry)
        try store.commit()
        
        XCTAssert(try store.fetch(entityType: Tag.self).count == 3)
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
    
    func testFetchPredicateRelationships() throws {
        let aEntry = Entry(id: "a", tags: [Tag(id: "a", name: "A"), Tag(id: "b", name: "B")])
        let bEntry = Entry(id: "b", tags: [Tag(id: "b", name: "B")])
        let cEntry = Entry(id: "c", tags: [Tag(id: "a", name: "A")])
        let dEntry = Entry(id: "d", tags: [])
        
        try store.save(entity: aEntry)
        try store.save(entity: bEntry)
        try store.save(entity: cEntry)
        try store.save(entity: dEntry)
        try store.commit()
        
        XCTAssert(try store.fetch(entityType: Entry.self, format: "%@ in tags.name", "A").count == 2)
    }
}
