# SwiftyCoreData

Define types `Int`, `Double`, `String`, `Bool`, `Date`, `Data`, `UUID`, `URL` or enums with `SCDField`

Enums should be `RawRepresentable` and comform to `SCDIntegerEnum` or `SCDStringEnum`

Define inner structs and arrays with `FieldType.transformable`

``` swift
struct Entry {
    struct InnerEntry: Codable {
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
            SCDField(name: "id", type: .integer),
            SCDField(name: "title", type: .string),
            SCDField(name: "date", type: .date, optional: true),
            SCDField(name: "inner", type: .transformable),
            SCDField(name: "kind", type: .string)
        ])
    }
}
```

Add all entities to SCDManagedObjectModel:

``` swift
let store = SCDStore(model: SCDManagedObjectModel(entities: [
        Entry.self
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

### Observation

Observe entities with `observe<T: SCDEntity>(entityType: T.Type, _ observeHandler: @escaping (Changes<T>) -> Void) throws -> Observation` method

`Changes` contain inserted, updated and deleted entities:

``` swift
try store.observe(entityType: Entry.self) { changes in
    print(changes)
}
```

## Installation

### Swift Package Manager

```
https://github.com/smyshlaevalex/SwiftyCoreData.git
```
