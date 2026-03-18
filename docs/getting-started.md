# Getting Started

## Creating a Catalog

A `Catalog` is an in-memory collection of named items. Each item is a struct (or table row) with at least a `Name` field.

```matlab
c = Catalog();
```

You can also initialize with existing data:

```matlab
data = struct('Name', {'Alice', 'Bob'}, 'Age', {30, 25});
c = Catalog(data);
c.NumItems   % 2
c.ItemNames  % ["Alice", "Bob"]
```

## Adding Items

Add items one at a time or in batch. A UUID is automatically assigned to each item.

```matlab
% Single item
c.add(struct('Name', 'Experiment_001', 'Status', "running", 'Score', 0.85));

% Batch add
items = struct('Name', {'Exp_002', 'Exp_003'}, 'Status', {"done", "pending"});
c.addMany(items);
```

Items can also be added as table rows:

```matlab
newRow = table("Exp_004", "queued", 0, 'VariableNames', {'Name', 'Status', 'Score'});
c.add(newRow);
```

!!! warning
    Item names must be unique. Adding a duplicate name throws a `Catalog:NamedItemExists` error.

## Retrieving Items

Retrieve items by name, UUID, or numeric index:

```matlab
% By name
item = c.get("Experiment_001");

% By index
firstItem = c.get(1);

% Get all items
allItems = c.getAll();
```

You can also use parenthesis indexing:

```matlab
item = c(1);       % First item
item = c(2);       % Second item
```

### Item representation

Control the return format with the `ItemRepresentation` property:

```matlab
c.ItemRepresentation = "struct";  % default — returns scalar struct
c.ItemRepresentation = "table";   % returns single-row table
c.ItemRepresentation = "object";  % returns instance of ItemClass
```

## Updating Items

Update a single field without replacing the entire item:

```matlab
c.update("Experiment_001", "Status", "completed");
c.update("Experiment_001", "Score", 0.95);
```

Or replace the entire item (UUID must match):

```matlab
item = c.get("Experiment_001");
item.Score = 0.99;
c.replace(item);
```

## Removing Items

```matlab
c.remove("Experiment_001");  % By name
c.remove(1);                 % By index
```

## Checking for Items

```matlab
[exists, index] = c.contains("Experiment_001");
```

## Listening to Events

Catalog fires events on mutations, which is useful for keeping UIs or dependent systems in sync:

```matlab
c = Catalog();
addlistener(c, 'ItemAdded',    @(src, evt) fprintf('Added: %s\n', evt.ItemName));
addlistener(c, 'ItemRemoved',  @(src, evt) fprintf('Removed: %s\n', evt.ItemName));
addlistener(c, 'ItemModified', @(src, evt) fprintf('Modified: %s\n', evt.ItemName));

c.add(struct('Name', 'Test', 'Value', 1));   % prints "Added: Test"
c.update("Test", "Value", 2);                % prints "Modified: Test"
```

## Persisting to Disk

`PersistentCatalog` extends `Catalog` with automatic file persistence:

```matlab
pc = PersistentCatalog('SaveFolder', './my_catalog');

% Items are saved automatically after each mutation
pc.add(struct('Name', 'Session_001', 'Subject', "Mouse_A"));
pc.add(struct('Name', 'Session_002', 'Subject', "Mouse_B"));

% Later, reload from the same folder
pc2 = PersistentCatalog('SaveFolder', './my_catalog');
pc2.NumItems  % 2
```

### Disabling auto-save

For batch operations, disable auto-save to avoid writing to disk on every mutation:

```matlab
pc = PersistentCatalog('SaveFolder', './data', 'AutoSave', false);

for i = 1:100
    pc.add(struct('Name', sprintf('Item_%03d', i), 'Value', rand()));
end

pc.save();  % Single write to disk
```

### Metadata

Store catalog-level configuration alongside the items:

```matlab
metadata = struct('Pipeline', 'preprocessing_v2', 'CreatedBy', 'lab_manager');
pc = PersistentCatalog('SaveFolder', './data', 'Metadata', metadata);
pc.add(struct('Name', 'Run_001', 'Value', 1));

% Metadata is saved and restored with the catalog
pc2 = PersistentCatalog('SaveFolder', './data');
pc2.Metadata.Pipeline  % "preprocessing_v2"
```

### Version tracking

Detect external modifications to the catalog file:

```matlab
pc = PersistentCatalog('SaveFolder', './data');
pc.isLatestVersion()  % true — file matches in-memory state

% If another process modifies the file:
pc.isLatestVersion()  % false — file has been changed externally
pc.load()             % Reload to get the latest version
```

### JSON export and import

Export the catalog to JSON for interoperability or inspection:

```matlab
pc.exportToJson('./export_folder');

% Import into another catalog
pc2 = PersistentCatalog('AutoSave', false);
pc2.importFromJson('./export_folder');
```

## Subclassing PersistentCatalog

Override hooks to customize load/save behavior:

```matlab
classdef ExperimentCatalog < PersistentCatalog

    methods (Access = protected)
        function data = modifyDataOnLoad(~, data)
            % Migrate legacy field names
            if istablevar(data, 'OldField')
                data.NewField = data.OldField;
                data.OldField = [];
            end
        end

        function data = cleanDataOnSave(~, data)
            % Remove transient columns before saving
            if istablevar(data, 'TempCache')
                data.TempCache = [];
            end
        end
    end
end
```
