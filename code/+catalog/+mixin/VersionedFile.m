classdef (Abstract) VersionedFile < handle
% VersionedFile - Mixin providing atomic file persistence with version tracking
%
%   Subclasses must implement:
%     S = toFileStruct(obj)              - Serialize object state to a struct
%     fromFileStruct(obj, S)             - Restore object state from a struct
%     writeToFile(obj, filePath, S)      - Write struct to file in chosen format
%     S = readFromFile(obj, filePath)    - Read struct from file in chosen format
%
%   Provides:
%     save(obj, force)           - Atomic save (temp -> verify -> copyfile)
%     load(obj)                  - Load state from file
%     saveCopy(obj, savePath)    - Save a copy without changing FilePath
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
        writeToFile(obj, filePath, S)
        S = readFromFile(obj, filePath)
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
            versionNumberInFile = obj.loadVersionNumber();
            tf = versionNumberInFile == obj.VersionNumber;
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
                if ~nargout; clear wasSaved; end
                return
            end

            fileStruct = obj.toFileStruct();

            % Increment version and embed in struct
            currentVersion = obj.loadVersionNumber();
            newVersion = currentVersion + 1;
            fileStruct.VersionNumber = newVersion;

            % Ensure target folder exists
            folderPath = fileparts(obj.FilePath);
            if ~isfolder(folderPath)
                mkdir(folderPath)
            end

            % Atomic save: write to temp file, verify, then copyfile
            tempFilePath = strrep(obj.FilePath, fileExtension(obj.FilePath), ".tempsave" + fileExtension(obj.FilePath));
            obj.writeToFile(tempFilePath, fileStruct);

            try
                verifiedData = obj.readFromFile(tempFilePath);
                assert(isstruct(verifiedData), 'Saved data is not a valid struct.')
            catch cause
                error('VersionedFile:SaveFailed', ...
                    'Verification failed. Backup at: %s\n%s', ...
                    tempFilePath, cause.message)
            end

            copyfile(char(tempFilePath), char(obj.FilePath));
            deleteFile(tempFilePath);

            obj.VersionNumber = newVersion;
            obj.markClean();
            wasSaved = true;

            if ~nargout; clear wasSaved; end
        end

        function load(obj)
            if ismissing(obj.FilePath)
                error('VersionedFile:NoFilePath', 'No file path specified.')
            end

            if ~isfile(obj.FilePath)
                error('VersionedFile:FileNotFound', ...
                    'File "%s" does not exist.', obj.FilePath)
            end

            fileStruct = obj.readFromFile(obj.FilePath);
            obj.fromFileStruct(fileStruct);

            if isfield(fileStruct, 'VersionNumber') && ~isempty(fileStruct.VersionNumber)
                obj.VersionNumber = int64(fileStruct.VersionNumber);
            else
                obj.VersionNumber = int64(0);
            end

            obj.markClean();
        end

        function saveCopy(obj, savePath)
        % saveCopy - Save a copy of this object to the given file path
            arguments
                obj
                savePath (1,1) string
            end

            originalPath = obj.FilePath;
            obj.FilePath = savePath;
            obj.save(true);
            obj.FilePath = originalPath;
        end
    end

    methods (Access = protected)
        function versionNumber = loadVersionNumber(obj)
        % loadVersionNumber - Read VersionNumber from file without full load
            if ismissing(obj.FilePath) || ~isfile(obj.FilePath)
                versionNumber = int64(0);
                return
            end

            try
                fileStruct = obj.readFromFile(obj.FilePath);
                if isfield(fileStruct, 'VersionNumber') && ~isempty(fileStruct.VersionNumber)
                    versionNumber = int64(fileStruct.VersionNumber);
                else
                    versionNumber = int64(0);
                end
            catch
                versionNumber = int64(0);
            end
        end
    end
end

% Local function to avoid name clash with built-in delete
function deleteFile(filePath)
    if isfile(filePath)
        delete(char(filePath));
    end
end

% Local function to extract file extension
function ext = fileExtension(filePath)
    [~, ~, ext] = fileparts(filePath);
end
