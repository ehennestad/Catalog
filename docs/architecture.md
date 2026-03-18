# Architecture

## Class hierarchy

```
                     handle
                    /      \
           VersionedFile    IsSerializable
           (persistence)    (format mgmt)
                |                |
              Catalog            |
                \              /
             PersistentCatalog
```

The library separates three concerns into distinct classes:

**Catalog** — In-memory collection with add/get/replace/update/remove, events, and indexing. No knowledge of files or serialization.

**VersionedFile** — Abstract mixin for atomic file persistence. Manages the save lifecycle (dirty check, version bump, temp file, verify, copy) and version tracking. Delegates the actual file I/O to four abstract methods that subclasses implement.

**IsSerializable** — Mixin that manages a pluggable serializer (MAT or JSON). Provides the `Serializer` object that knows how to read and write structs in a specific format.

**PersistentCatalog** — Inherits all three. Bridges the serializer into VersionedFile's abstract I/O methods, adds auto-save behavior, and handles backward-compatible loading of legacy file formats.

## How save works

```
obj.save()
  → VersionedFile.save()                   % dirty check, version bump
    → obj.toFileStruct()                   % PersistentCatalog packs ItemsData + Metadata
    → obj.writeToFile(tempPath, S)         % PersistentCatalog delegates to serializer
      → obj.Serializer.writeStruct(...)    % MatSerializer writes .mat file
    → obj.readFromFile(tempPath)           % verify round-trip
    → copyfile(tempPath, targetPath)       % atomic swap
    → markClean()
```

Each layer does one thing. VersionedFile owns the lifecycle, PersistentCatalog owns the data packing, and the serializer owns the format.

## Serializer design

Serializers implement the `catalog.serializer.abstract.StructSerializer` interface:

```
StructSerializer (abstract)
├── MatSerializer       — .mat files via save/load
└── JsonSerializer      — .json files via jsonencode/jsondecode
```

Each serializer provides two levels of I/O:

- **`writeStruct` / `readStruct`** — Raw scalar struct I/O, used by VersionedFile for atomic saves
- **`save` / `load`** — Catalog-level serialization (struct arrays with names), used for JSON export/import

Adding a new format (e.g., YAML) requires implementing one subclass of `StructSerializer`.

## Version tracking

VersionedFile uses counter-based versioning. The `VersionNumber` is an `int64` stored inside the file alongside the data. On each save, the counter increments. `isLatestVersion()` compares the in-memory counter to the one in the file, detecting external modifications without loading the full dataset.

## Event system

Catalog fires three events when items are mutated:

| Event | Trigger | Payload |
|-------|---------|---------|
| `ItemAdded` | `add()`, `addMany()` | Item name, index, data |
| `ItemRemoved` | `remove()` | Item name, index, data (captured before removal) |
| `ItemModified` | `replace()`, `update()` | Item name, index, data |

All events carry a `CatalogEventData` object with `ItemName`, `ItemIndex`, and `ItemData` properties.

## Item storage

Internally, items are stored in a `catalog.item.ItemData` container that wraps either a struct array or a table. The wrapper provides custom indexing (`obj(i)`) and transparent field access while hiding the underlying storage format.

The `ItemRepresentation` property on Catalog controls how items are returned to the caller — as structs, table rows, or objects of a specified class.
