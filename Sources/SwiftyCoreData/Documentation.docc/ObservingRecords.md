# Observing records

Observe changes to records.

## Overview

Create a ``Record`` observer using ``PersistentStore/observe(recordType:_:)``, passing ``Record`` type and a handler.

Observe handler has one parameter - ``PersistentStore/Changes`` which containes inserted, updated and deleted records.

This method returns ``PersistentStore/Observation`` object, which requires strong reference to continue observing, will automaticlly stop observation when deallocated, set it to `nil` to stop observation sooner.

```swift
observation = try store.observe(recordType: TodoItem.self) { changes in
    print(changes.inserted)
    print(changes.updated)
    print(changes.deleted)
}
```
