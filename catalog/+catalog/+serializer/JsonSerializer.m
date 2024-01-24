classdef JsonSerializer < catalog.serializer.abstract.StructSerializer
    
    % Note: This class is for serializing structs to json format

    % Todo
    % [ ] Make option/preference to save to individual json files or one
    %     json file?
    % [ ] Not optimized for performance. Should have Dirty flag for each
    %     item, and only save changes...
    % [ ] Granular saving. I.e save/delete individual item...
    % [ ] Implement saving with backup on superclass...


    properties (Constant, Hidden)
        SerializationFormat = ".json"
    end
    
    methods % Constructor
        
        function obj = JsonSerializer(superPropertyArgs)
            arguments
                superPropertyArgs.?catalog.serializer.abstract.StructSerializer % Include public properties from superclass in argument block.
            end

            % Pass property arguments to superclass
            superArgsCell = namedargs2cell(superPropertyArgs);
            obj = obj@catalog.serializer.abstract.StructSerializer(superArgsCell{:})

            % Assign property arguments for this concrete class
            %obj.assignPropertyArguments(propertyArgs)
        end
    end

    methods
        function save(obj, entries, options)
            % Todo: Save preferences/attributes
            % Todo: Delete old data before saving.
            arguments
                obj (1,1) catalog.serializer.JsonSerializer
                entries (1,:) struct
                options.Names (1,:) string = string.empty
                options.VariableName (1,1) string = "entries" 
            end

            if isfolder(obj.PathName)
                [cleanupObj, backupPathName] = obj.backupCatalog(); %#ok<ASGLU>
            end

            for i = 1:numel(entries)
                jsonStr = jsonencode(entries(i), 'PrettyPrint', true);
                fileName = obj.createFilename(options.Names{i});
                savePath = fullfile(obj.PathName, fileName);
                obj.filewrite(savePath, jsonStr)
            end
            
            rmdir(backupPathName, 's')
            clear cleanupObj
        end

        function data = load(obj)
            L = dir(fullfile(obj.PathName, "*"+obj.SerializationFormat));
            
            data = cell(1,numel(L));
            for i = 1:numel(L)
                jsonStr = fileread(fullfile(L(i).folder, L(i).name));
                data{i} = jsondecode(jsonStr);
            end
            data = [data{:}];
        end
    end

    methods (Access = protected) % Subclasses may implement
        
        function onPathNameSet(obj)
            if ismissing(obj.PathName); return; end

            % Ensure path is without extension
            [folderName, name, ext] = fileparts(obj.PathName);
            if ext ~= ""
                obj.PathName = fullfile(folderName, name);
            end
        end

        function validateFileName(obj)
        % validateFileName - Make sure path name has the correct file extension
            if ismissing(obj.PathName); return; end

            [~, ~, ext] = fileparts(obj.PathName);
            if ext == "" % Path name is a folder (Saving to individual json files)
                return
            else
                validateFileName@catalog.serializer.abstract.StructSerializer(obj)
            end
        end
    end

    methods (Access = private)
        
        function fileName = createFilename(obj, name)
            validName = matlab.lang.makeValidName(name);
            fileName = validName + obj.SerializationFormat;
        end

        function [cleanupObj, backupPathName] = backupCatalog(obj)
            [folderPath, name] = fileparts(obj.PathName);
            backupName = name + "_" + obj.getTimestamp();
            backupPathName = fullfile(folderPath, backupName);
            movefile(obj.PathName, backupPathName)

            cleanupObj = onCleanup(...
                @(s,t) obj.restoreCatalog(obj.PathName, backupPathName));
        end

        function restoreCatalog(~, originalPath, backupPath)
            if isfolder(backupPath)
                rmdir(originalPath, 's');
                movefile(backupPath, originalPath)
            end
        end
    end

    methods (Static, Access = private)
        function timestamp = getTimestamp()
            timestamp = string(datetime("now", 'Format', 'yyyy_MM_dd_hhmmss'));
        end
    end

    methods (Static)
        function filewrite(filePath, textStr)
            folderPath = char(fileparts(filePath));
            
            if ~isempty(folderPath) && ~isfolder(folderPath)
                mkdir(folderPath)
            end
            
            fid = fopen(filePath, 'w');
            fwrite(fid, textStr);
            fclose(fid);
        end
    end
end