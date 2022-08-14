# Migration

Migrating ``PersistentStore`` after making changes to records.

## Overview

When it's time to update your model you will need to migrate your data. Here is how you can do it.

Increment model version in ``StoreModel/init(version:records:)``.

```swift
let store = PersistentStore(version: 2, model: StoreModel(records: [
    TODOItem.self, Indicator.self
]))
```

Migration happens in steps, for example when migrating from version 2 to version 4, first data will be migrated to version 3 and then to version 4.

Update your records and return different fields in ``Record/recordDescription(for:)`` depending on version.

### Migration supports

- Changing property from optional to non-optional and in reverse.
- Renaming property.
- Adding new property.
- Removing existing property.

### Migration does not support

- Changing type of a property.
- Renaming records.

When adding new optional property just add a new field.

```swift
struct TodoItem: Record {
    var id = UUID()
    var creationDate = Date()
    var title: String
    var contents: String
    var tag: Tag?
    var isCompleted: Bool
    var newProperty: URL?

    static func recordDescription(for version: Int) -> RecordDescription {
        Field(primaryKey: true, name: "id", type: .uuid)
        Field(name: "creationDate", type: .uuid)
        Field(name: "title", type: .string)
        Field(name: "contents", type: .string)
        Field(name: "tag", type: .transformable, optional: true)
        Field(name: "isCompleted", type: .boolean)

        if version > 1 {
            Field(name: "newProperty", type: .url, optional: true)
        }
    }
}
```

When adding new non-optional property or changing property from optional to non-optional provide ``Field/MigrationInfo`` with default value.

```swift
struct TodoItem: Record {
    var id = UUID()
    var creationDate = Date()
    var title: String
    var contents: String
    var tag: Tag?
    var isCompleted: Bool
    var newProperty: Double

    static func recordDescription(for version: Int) -> RecordDescription {
        Field(primaryKey: true, name: "id", type: .uuid)
        Field(name: "creationDate", type: .uuid)
        Field(name: "title", type: .string)
        Field(name: "contents", type: .string)
        Field(name: "tag", type: .transformable, optional: true)
        Field(name: "isCompleted", type: .boolean)

        if version > 1 {
            Field(name: "newProperty", type: .double, migrationInfo: .init(default: 10.5))
        }
    }
}
```

When renaming a property provide ``Field/MigrationInfo`` with renamingID, which has to be the original name of the property.

```swift
struct TodoItem: Record {
    var id = UUID()
    var creationDate = Date()
    var name: String
    var contents: String
    var tag: Tag?
    var isCompleted: Bool

    static func recordDescription(for version: Int) -> RecordDescription {
        Field(primaryKey: true, name: "id", type: .uuid)
        Field(name: "creationDate", type: .uuid)
        Field(name: "contents", type: .string)
        Field(name: "tag", type: .transformable, optional: true)
        Field(name: "isCompleted", type: .boolean)

        if version < 2 {
            Field(name: "title", type: .string)
        } else if version > 1 {
            Field(name: "name", type: .string, migrationInfo: .init(renamingID: "title"))
        }
    }
}
```

Migrate ``Field/FieldType/transformable`` structs by adding manual decoding and encoding.
