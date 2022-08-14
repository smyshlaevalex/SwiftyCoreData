# Saving, Fetching and Deleting records

Use ``PersistentStore`` to manipulate records

## Overview

Create ``PersistentStore`` by providing an optional name ("SwiftyCoreDataStore" is default), optional type (`sqLite` is default) and ``StoreModel``.

Create ``StoreModel`` by providing optional version and all ``Record`` types that will be used  with ``PersistentStore``.

```swift
let store = PersistentStore(model: StoreModel(records: [
    TodoItem.self, Indicator.self
]))
```

Save records using ``PersistentStore/save(record:)`` method.

```swift
try store.save(record: todoItem)
```

Fetch all records of a provided type using ``PersistentStore/fetch(recordType:)`` method.

```swift
let todoItems = try store.fetch(recordType: TodoItem.self)
```

Fetch a ``Record`` of a provided type with provided id using ``PersistentStore/fetch(recordType:withId:)`` method.

```swift
let indicator = try store.fetch(recordType: Indicator.self, withId: 4)
```

Fetch all records of a provided type matching a predicate using ``PersistentStore/fetch(recordType:format:_:)`` or ``PersistentStore/fetch(recordType:format:arguments:)`` methods.

```swift
let todoItems = try store.fetch(
    recordType: TodoItem.self,
    format: "creationDate >= %@",
    Calendar.current.startOfDay(for: Date())
)
```

Delete records using ``PersistentStore/delete(records:)`` or ``PersistentStore/delete(record:)`` methods.

```swift
try store.delete(records: [todoItem1, todoItem2])

try store.delete(record: indicator)
```
