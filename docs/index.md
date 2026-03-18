# Catalog

A MATLAB library for managing collections of named, uniquely identified items with optional file persistence.

## What is Catalog?

Catalog provides a structured way to manage collections of items — similar to a dictionary with ordering, or a database table with named rows. Each item has a unique name and a UUID, and can carry arbitrary fields.

Key capabilities:

- **In-memory collections** — Add, get, replace, update, and remove items by name, UUID, or index
- **File persistence** — Atomic saves with version tracking and dirty-state management
- **Pluggable serialization** — MAT (default) and JSON formats, extensible to others
- **Event notifications** — React to item additions, removals, and modifications
- **Backward compatibility** — Loads legacy file formats transparently

## Quick example

```matlab
% Create an in-memory catalog
c = Catalog();
c.add(struct('Name', 'Experiment_001', 'Subject', 'Mouse_A', 'Date', "2024-03-15"));
c.add(struct('Name', 'Experiment_002', 'Subject', 'Mouse_B', 'Date', "2024-03-16"));

% Retrieve and update items
item = c.get("Experiment_001");
c.update("Experiment_001", "Subject", "Mouse_C");

% Persistent catalog — auto-saves to disk
pc = PersistentCatalog('SaveFolder', '/path/to/data');
pc.add(struct('Name', 'Session_001', 'Status', "pending"));

% Reload later — picks up where you left off
pc2 = PersistentCatalog('SaveFolder', '/path/to/data');
pc2.get("Session_001")  % Status: "pending"
```

## Installation

Clone or download this repository and add the `code` folder to your MATLAB path:

```matlab
addpath('/path/to/Catalog/code')
```

## Requirements

- MATLAB R2021a or later
