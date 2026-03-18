classdef (Abstract) VersionedFile < handle
% VersionedFile - Mixin providing atomic file save, version tracking, and dirty state
%
%   Subclasses must implement:
%     S = toFileStruct(obj)      - Return a struct representing the object state
%     fromFileStruct(obj, S)     - Restore object state from a struct
%
%   Provides:
%     save(obj, force)           - Atomic save (temp -> verify -> rename)
%     load(obj)                  - Load state from file
%     isClean(obj)               - True if no unsaved changes
%     markClean(obj)             - Clear dirty flag
%     markDirty(obj)             - Set dirty flag
%     isLatestVersion(obj)       - True if file has not been modified externally

    properties (SetAccess = protected)
        FilePath (1,1) string = missing
    end

    properties (SetAccess = protected)
        VersionNumber (1,1) int64 = int64(0)
    end

    properties (Access = private)
        IsDirty (1,1) logical = false
    end

    methods (Abstract, Access = protected)
        S = toFileStruct(obj)
        fromFileStruct(obj, S)
    end

    methods
        function tf = isClean(obj)
            tf = ~obj.IsDirty;
        end

        function markClean(obj)
            obj.IsDirty = false;
        end

        function markDirty(obj)
            obj.IsDirty = true;
        end

        function tf = isLatestVersion(obj)
            if ismissing(obj.FilePath) || ~isfile(obj.FilePath)
                tf = true;
                return
            end
            fileTimestamp = getFileTimestamp(obj.FilePath);
            tf = fileTimestamp <= obj.VersionNumber;
        end

        function wasSaved = save(obj, force)
            arguments
                obj
                force (1,1) logical = false
            end

            wasSaved = false;

            if ismissing(obj.FilePath)
                error('VersionedFile:NoFilePath', 'No file path specified.')
            end

            if obj.isClean() && ~force
                return
            end

            fileStruct = obj.toFileStruct();

            % Atomic save: write to temp file, verify, then rename
            folderPath = fileparts(obj.FilePath);
            if ~isfolder(folderPath)
                mkdir(folderPath)
            end

            tempFilePath = obj.FilePath + ".tmp";
            saveStructToMatFile(char(tempFilePath), fileStruct)

            % Verify the temp file loads correctly
            try
                verifiedData = loadMatFile(char(tempFilePath));
                assert(isstruct(verifiedData), 'Saved data is not a valid struct.')
            catch cause
                if isfile(tempFilePath); delete(tempFilePath); end
                exception = MException('VersionedFile:SaveFailed', ...
                    'Verification of saved file failed: %s', cause.message);
                throw(exception)
            end

            % Rename temp file over target
            if isfile(obj.FilePath)
                delete(obj.FilePath)
            end
            moveFile(char(tempFilePath), char(obj.FilePath))

            obj.VersionNumber = getFileTimestamp(obj.FilePath);
            obj.markClean();
            wasSaved = true;

            if ~nargout
                clear wasSaved
            end
        end

        function load(obj)
            if ismissing(obj.FilePath)
                error('VersionedFile:NoFilePath', 'No file path specified.')
            end

            if ~isfile(obj.FilePath)
                return
            end

            fileStruct = loadMatFile(char(obj.FilePath));
            obj.fromFileStruct(fileStruct)

            obj.VersionNumber = getFileTimestamp(obj.FilePath);
            obj.markClean();
        end
    end
end

% Local functions to avoid name clashes with class methods

function saveStructToMatFile(filePath, S) %#ok<INUSD>
    save(filePath, '-struct', 'S')
end

function S = loadMatFile(filePath)
    S = load(filePath, '-mat');
end

function moveFile(source, target)
    movefile(source, target)
end

function timestamp = getFileTimestamp(filePath)
    fileInfo = dir(filePath);
    timestamp = int64(fileInfo.datenum * 1e6);
end
