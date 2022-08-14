# Creating a Record

Create a ``Record`` type.

## Overview

To make structs usable with ``PersistentStore`` they need to conform to ``Record`` protocol.
This requires conforming to `Codable` protocol and implementing static ``Record/recordDescription(for:)`` method.

``Record/recordDescription(for:)`` method uses result builder to build a description of struct properties.

```swift
struct TodoItem: Record {
    var id = UUID()
    var creationDate = Date()
    var title: String
    var contents: String
    var tag: Tag?
    var isCompleted: Bool

    static func recordDescription(for version: Int) -> RecordDescription {
        Field(primaryKey: true, name: "id", type: .uuid)
        Field(name: "creationDate", type: .uuid)
        Field(name: "title", type: .string)
        Field(name: "contents", type: .string)
        Field(name: "tag", type: .transformable, optional: true)
        Field(name: "isCompleted", type: .boolean)
    }
}

struct Tag: Codable {
    let name: String
}
```

When using enums make sure to conform them to ``RecordIntegerEnum`` or ``RecordStringEnum``.

```swift
struct Indicator: Record {
    enum Kind: String, RecordStringEnum {
        case big
        case small
    }

    var id: Int
    var kind: Kind

    static func recordDescription(for version: Int) -> RecordDescription {
        Field(primaryKey: true, name: "id", type: .integer)
        Field(name: "kind", type: .string)
    }
}
```
