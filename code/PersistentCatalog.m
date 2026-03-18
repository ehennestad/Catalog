classdef PersistentCatalog < Catalog & catalog.mixin.VersionedFile & catalog.mixin.IsSerializable
% PersistentCatalog - A catalog which is stored on the file system
%
%   Uses VersionedFile for atomic save, version tracking, and dirty state.
%   Uses IsSerializable for pluggable serialization format management.
%
%   On load, the mat file is preferred. If no mat file exists, falls back
%   to loading from a json folder if one is present.
%
%   Supports loading legacy files where items are stored as a struct array
%   in a 'Data' or 'entries' field, and catalog-level config is stored in
%   a 'Preferences' field.

    properties
        SaveFolder (1,1) string = missing
        AutoSave (1,1) logical = true
    end

    properties (SetAccess = protected)
        Metadata (1,1) struct = struct()
    end

    properties (Constant, Access = private)
        DEFAULT_FILENAME (1,1) string = "catalog.mat"
    end

    methods % Constructor
        function obj = PersistentCatalog(options)
            arguments
                options.SaveFolder (1,1) string = missing
                options.AutoSave (1,1) logical = true
                options.Metadata (1,1) struct = struct()
            end

            obj.AutoSave = options.AutoSave;
            obj.Metadata = options.Metadata;

            if ~ismissing(options.SaveFolder)
                obj.SaveFolder = options.SaveFolder;
                obj.load()
            end
        end
    end

    methods % Set methods
        function set.SaveFolder(obj, value)
            obj.SaveFolder = value;
            if ~ismissing(value)
                obj.FilePath = fullfile(value, obj.DEFAULT_FILENAME);
            end
        end
    end

    methods % Overrides for auto-save and dirty tracking
        function newItem = add(obj, newItem)
            newItem = add@Catalog(obj, newItem);
            obj.markDirty();
            if obj.AutoSave
                obj.save();
            end
            if ~nargout
                clear newItem
            end
        end

        function addMany(obj, items)
            addMany@Catalog(obj, items);
            obj.markDirty();
            if obj.AutoSave
                obj.save();
            end
        end

        function remove(obj, identifier)
            remove@Catalog(obj, identifier);
            obj.markDirty();
            if obj.AutoSave
                obj.save();
            end
        end

        function newItem = replace(obj, newItem)
            newItem = replace@Catalog(obj, newItem);
            obj.markDirty();
            if obj.AutoSave
                obj.save();
            end
            if ~nargout
                clear newItem
            end
        end

        function update(obj, identifier, fieldName, newValue)
            update@Catalog(obj, identifier, fieldName, newValue);
            obj.markDirty();
            if obj.AutoSave
                obj.save();
            end
        end
    end

    methods % Override load to add json fallback
        function load(obj)
            if ~ismissing(obj.FilePath) && isfile(obj.FilePath)
                load@catalog.mixin.VersionedFile(obj);
            else
                % Fall back to json if mat file does not exist
                jsonFolderPath = obj.getJsonFolderPath();
                if ~ismissing(jsonFolderPath) && isfolder(jsonFolderPath)
                    obj.importFromJson(jsonFolderPath);
                end
            end
        end
    end

    methods % Json export/import
        function exportToJson(obj, filePath)
        % exportToJson - Export current catalog state to json format
            arguments
                obj (1,1) PersistentCatalog
                filePath (1,1) string = missing
            end

            if ismissing(filePath)
                filePath = obj.getJsonFolderPath();
            end

            if ismissing(filePath)
                error('PersistentCatalog:NoPath', ...
                    'No file path specified for json export.')
            end

            serializer = catalog.serializer.JsonSerializer('PathName', filePath);
            data = table2struct(obj.ItemsData);
            serializer.save(data, 'Names', obj.ItemNames);
        end

        function importFromJson(obj, filePath)
        % importFromJson - Import catalog state from json format
            arguments
                obj (1,1) PersistentCatalog
                filePath (1,1) string
            end

            serializer = catalog.serializer.JsonSerializer('PathName', filePath);
            data = serializer.load();

            if ~isempty(data)
                loadedData = struct2table(data);
                loadedData = obj.modifyDataOnLoad(loadedData);
                obj.ItemsData = loadedData;
                obj.markDirty();
            end
        end
    end

    methods (Access = protected) % VersionedFile abstract: data packing
        function S = toFileStruct(obj)
            data = obj.cleanDataOnSave(obj.ItemsData);
            S.ItemsData = data;
            S.Metadata = obj.Metadata;
        end

        function fromFileStruct(obj, S)
            % New format: ItemsData field with table
            if isfield(S, 'ItemsData')
                data = S.ItemsData;
                if isstruct(data) && ~isempty(data)
                    data = struct2table(data);
                end

            % Legacy format: Data field with struct array
            elseif isfield(S, 'Data')
                data = S.Data;
                if isstruct(data) && ~isempty(data)
                    data = struct2table(data);
                end

            % Legacy format: entries field (from old MatSerializer)
            elseif isfield(S, 'entries')
                data = S.entries;
                if isstruct(data) && ~isempty(data)
                    data = struct2table(data);
                end

            else
                data = table();
            end

            if ~isempty(data) && istable(data)
                data = obj.modifyDataOnLoad(data);
                obj.ItemsData = data;
            end

            % Metadata: new format or legacy Preferences
            if isfield(S, 'Metadata')
                obj.Metadata = S.Metadata;
            elseif isfield(S, 'Preferences')
                obj.Metadata = S.Preferences;
            end
        end
    end

    methods (Access = protected) % VersionedFile abstract: file I/O via serializer
        function writeToFile(obj, filePath, S)
            obj.Serializer.writeStruct(filePath, S);
        end

        function S = readFromFile(obj, filePath)
            S = obj.Serializer.readStruct(filePath);
        end
    end

    methods (Access = protected) % Load/save hooks for subclass customization
        function data = modifyDataOnLoad(~, data)
        % modifyDataOnLoad - Override in subclass to migrate/fix data after loading
        end

        function data = cleanDataOnSave(~, data)
        % cleanDataOnSave - Override in subclass to clean data before saving
        end
    end

    methods (Access = private)
        function jsonPath = getJsonFolderPath(obj)
        % getJsonFolderPath - Derive the json folder path from SaveFolder
            if ismissing(obj.SaveFolder)
                jsonPath = missing;
                return
            end
            [~, name] = fileparts(obj.DEFAULT_FILENAME);
            jsonPath = fullfile(obj.SaveFolder, name);
        end
    end
end
