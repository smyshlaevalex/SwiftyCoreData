# SwiftyCoreData

Define types `Int`, `Double`, `String`, `Bool`, `Date`, `Data`, `UUID`, `URL` or enums with `SCDAttributeField`

Enums should be `RawRepresentable` and comform to `SCDIntegerEnum` or `SCDStringEnum`

Define inner structs with `SCDRelationshipField`, add `.array()` for array of structs

``` swift
struct Entry {
    struct InnerEntry {
        let id: UUID
        let iconUrl: URL
    }
    
    enum Kind: String, SCDStringEnum {
        case small
        case big
    }

    let id: Int
    let title: String
    let date: Date?
    let inner: InnerEntry
    let kind: Kind
}
```

Add entity description:

``` swift
extension Entry: SCDEntity {
    static var entityDescription: SCDEntityDescription {
        SCDEntityDescription(id: "id", fields: [
            SCDAttributeField(name: "id", type: .integer),
            SCDAttributeField(name: "title", type: .string),
            SCDAttributeField(name: "date", type: .date).optional(),
            SCDRelationshipField(name: "inner", type: InnerEntry.self),
            SCDAttributeField(name: "kind", type: .string)
        ])
    }
}

extension Entry.InnerEntry: SCDEntity {
    static var entityDescription: SCDEntityDescription {
        SCDEntityDescription(id: "id", fields: [
            SCDAttributeField(name: "id", type: .uuid),
            SCDAttributeField(name: "iconUrl", type: .url)
        ])
    }
}
```

Add all entities (including inner entities) to SCDManagedObjectModel:

``` swift
let store = SCDStore(model: SCDManagedObjectModel(entities: [
        Entry.self, Entry.InnerEntry.self
    ]), name: "Model")
```

Save, fetch, delete entities:

``` swift
try store.save(entity: entry)
try store.fetch(entityType: Entry.self)
try store.fetch(entityType: Entry.self, withId: 1)
try store.delete(entity: entry)
```

Commit changed afterwards:

``` swift
try store.commit()
```
