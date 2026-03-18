# API Reference

## Catalog

In-memory collection of named, uniquely identified items.

### Constructor

```matlab
obj = Catalog()
obj = Catalog(data)
obj = Catalog(data, Name=Value)
```

**Arguments:**

| Name | Type | Description |
|------|------|-------------|
| `data` | struct array or table | Initial items (optional) |

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Description` | string | `""` | User-facing description |
| `ItemRepresentation` | `"struct"` \| `"table"` \| `"object"` | `"struct"` | Return format for retrieved items |
| `ItemNames` | string (read-only) | — | Names of all items |
| `NumItems` | double (read-only) | — | Number of items |

**Configuration properties** (Hidden):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `ItemType` | string | `missing` | Label for items (used in error messages) |
| `ItemClass` | string | `"struct"` | Class name when `ItemRepresentation = "object"` |
| `ItemConstructorInputType` | `"struct"` \| `"table"` \| `"nvpairs"` | `"struct"` | How to pass data to the item constructor |
| `NameField` | string | `"Name"` | Field used as item name |
| `IDField` | string | `"Uuid"` | Field used as unique identifier |

### Methods

#### `add`

```matlab
newItem = add(obj, newItem)
```

Add a single item to the catalog. The item must have a `Name` field (or whatever `NameField` is set to). A UUID is assigned automatically. Fires `ItemAdded`.

**Errors:** `Catalog:NamedItemExists` if name already exists, `Catalog:MissingName` if name field is absent.

---

#### `addMany`

```matlab
addMany(obj, items)
```

Add multiple items at once. Accepts a struct array or table. UUIDs are assigned to items that don't have one. Validates that no duplicate names exist within the batch or against existing items. Fires `ItemAdded` for each item.

---

#### `get`

```matlab
item = get(obj, identifier)
```

Retrieve an item by name (string), UUID (string), or row index (numeric). Returns the item in the format specified by `ItemRepresentation`.

**Errors:** `Catalog:ItemNotFound` if no match is found.

---

#### `getAll`

```matlab
data = getAll(obj)
```

Retrieve all items. Returns a struct array, table, or object array depending on `ItemRepresentation`.

---

#### `replace`

```matlab
newItem = replace(obj, newItem)
```

Replace an existing item. The replacement must have a matching UUID. Fires `ItemModified`.

---

#### `update`

```matlab
update(obj, identifier, fieldName, newValue)
```

Update a single field on an existing item. The identifier can be a name, UUID, or index. Fires `ItemModified`.

---

#### `remove`

```matlab
remove(obj, identifier)
```

Remove an item by name, UUID, or index. Fires `ItemRemoved`.

---

#### `contains`

```matlab
[tf, idx] = contains(obj, itemName)
```

Check if an item with the given name exists. Returns a logical flag and the row index (0 if not found).

---

#### `getBlankItem`

```matlab
blankItem = getBlankItem(obj)
```

Return a template item with the same fields as existing items but empty values. Useful for building forms or initializing new items.

---

### Events

| Event | Trigger | Payload |
|-------|---------|---------|
| `ItemAdded` | `add`, `addMany` | `CatalogEventData` |
| `ItemRemoved` | `remove` | `CatalogEventData` |
| `ItemModified` | `replace`, `update` | `CatalogEventData` |

### Indexing

```matlab
item = obj(1);      % Get first item
item = obj(2);      % Get second item
```

---

## PersistentCatalog

A Catalog that persists to disk with atomic saves and version tracking. Inherits from `Catalog`, `catalog.mixin.VersionedFile`, and `catalog.mixin.IsSerializable`.

### Constructor

```matlab
obj = PersistentCatalog(Name=Value)
```

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `SaveFolder` | string | `missing` | Directory for catalog storage. If provided, loads existing data on construction. |
| `AutoSave` | logical | `true` | Save to disk after every mutation |
| `Metadata` | struct | `struct()` | Catalog-level metadata stored alongside items |

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `SaveFolder` | string | `missing` | Directory for persistent storage |
| `AutoSave` | logical | `true` | Auto-save on mutations |
| `Metadata` | struct (protected) | `struct()` | Stored/loaded with the catalog file |

### Methods

All `Catalog` methods are available. Mutations (`add`, `addMany`, `remove`, `replace`, `update`) automatically mark the catalog as dirty and save if `AutoSave` is enabled.

#### `save`

```matlab
wasSaved = save(obj)
wasSaved = save(obj, true)   % force save even if clean
```

Save the catalog to disk atomically. Inherited from `VersionedFile`.

---

#### `load`

```matlab
load(obj)
```

Load catalog from disk. Tries the MAT file first, falls back to a JSON folder if no MAT file exists.

---

#### `exportToJson`

```matlab
exportToJson(obj)
exportToJson(obj, folderPath)
```

Export all items to individual JSON files. Defaults to a `catalog/` subfolder inside `SaveFolder`.

---

#### `importFromJson`

```matlab
importFromJson(obj, folderPath)
```

Import items from a folder of JSON files.

---

#### `isLatestVersion`

```matlab
tf = isLatestVersion(obj)
```

Returns `true` if the in-memory version matches the file. Useful for detecting external modifications.

---

#### `isClean` / `markDirty` / `markClean`

```matlab
tf = isClean(obj)
markDirty(obj)
markClean(obj)
```

Query and manage the dirty state. Mutations call `markDirty()` automatically; `save()` calls `markClean()`.

---

#### `saveCopy`

```matlab
saveCopy(obj, targetPath)
```

Save a copy of the catalog to a different file path without changing the object's `FilePath`.

---

### Subclass hooks

Override these protected methods to customize load/save behavior:

| Method | Signature | Purpose |
|--------|-----------|---------|
| `modifyDataOnLoad` | `data = modifyDataOnLoad(obj, data)` | Migrate or fix data after loading |
| `cleanDataOnSave` | `data = cleanDataOnSave(obj, data)` | Clean data before saving |

---

## CatalogEventData

Event data payload for catalog mutation events. Inherits from `event.EventData`.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ItemName` | string | Name of the affected item |
| `ItemIndex` | double | Row index of the affected item |
| `ItemData` | varies | The item data (struct, table row, or empty) |
