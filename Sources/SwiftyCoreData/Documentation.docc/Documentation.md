# ``SwiftyCoreData``

Package for saving structs in CoreData.

## Overview

This package offers a subset of CoreData functionally and is made to be easy to use.
CoreData works with `NSManagedObject` objects, while this package works with structs.

Swift Playgrounds for iPad does not offer an easy way to use CoreData due to inability to create xcdatamodeld files.

This package is fully usable and compatible with Swift Playgrounds.

## Topics

### Creating records

- <doc:CreatingRecord>
- ``Record``
- ``RecordDescription``
- ``Field``
- ``RecordIntegerEnum``
- ``RecordStringEnum``

### Saving, Fetching and Deleting records

- <doc:RecordManipulation>
- ``PersistentStore``
- ``StoreModel``

### Observing records

- <doc:ObservingRecords>
- ``PersistentStore/Observation``
- ``PersistentStore/Changes``

### Migration

- <doc:Migration>
- ``Field/MigrationInfo``
