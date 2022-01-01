# SwiftyCoreData

Define types `Int`, `Double`, `String`, `Bool`, `Date`, `Data`, `UUID`, `URL` with `SCDAttributeField`

Define inner structs with `SCDRelationshipField`

``` swift
struct Entry {
    struct InnerEntry {
        let id: UUID
        let iconUrl: URL
    }

    let id: Int
    let title: String
    let date: Date
    let inner: InnerEntry
}
```

Add entity description:

``` swift
extension Entry: SCDEntity {
    static var entityDescription: SCDEntityDescription {
        SCDEntityDescription(id: "id", fields: [
            SCDAttributeField(name: "id", type: .integer),
            SCDAttributeField(name: "title", type: .string),
            SCDAttributeField(name: "date", type: .date),
            SCDRelationshipField(name: "inner", type: InnerEntry.self)
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
