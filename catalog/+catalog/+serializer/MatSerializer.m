classdef MatSerializer < catalog.serializer.abstract.StructSerializer
    
    % Todo:
    % Implement saving in such a way that old file is backed up and only
    % remove if new file is saved and confirmed a valid matfile...

    properties (Constant, Hidden)
        SerializationFormat = ".mat"
    end

    properties (Constant, Access = private)
        DEFAULT_FILENAME = "struct_array"
    end

    methods
        function save(obj, entries, options)
            arguments
                obj (1,1) catalog.serializer.MatSerializer
                entries (1,:) struct
                options.Names (1,:) string = string.empty
                options.VariableName (1,1) string = "entries" 
            end

            S = struct(options.VariableName, entries);

            folderPath = fileparts(obj.PathName);
            if ~isfolder(folderPath); mkdir(folderPath); end
            save(obj.PathName, '-struct', 'S')
        end

        function data = load(obj)
            if isfile(obj.PathName)
                S = load(obj.PathName);
                varName = fieldnames(S);
                data = S.(varName{1});
            else
                data = struct.empty;
            end
        end
    end

    methods (Access = protected) % Subclasses may implement
        function onPathNameSet(obj)
            if ismissing(obj.PathName); return; end

            % Ensure path is a mat file
            if isfolder(obj.PathName)
                % Make a generic filename
                fileName = obj.DEFAULT_FILENAME + obj.SerializationFormat;
                obj.PathName = fullfile(obj.PathName, fileName);
            end
        end
    end

end