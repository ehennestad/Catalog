classdef (Abstract) StructSerializer < catalog.mixin.HasPropertyArgs

    % Todo: 
    %  [ ] Formalize preferences/attributes/configuration
    %  [ ] Back up old catalog during saving


    properties (Abstract, Constant, Hidden)
        % SerializationFormat - The file format which is used for saving
        % data during serialization. The value of this property should be 
        % the file extension, e.g ".mat" or ".json"
        SerializationFormat (1,1) string
    end

    properties
        % PathName - The path name for a file or folder where to save the
        % serialized structure elements. If the concrete serializer saves
        % all structure elements to one file, the pathname should be the
        % path of a file, whereas if the serializer saves each structure
        % element to an individual file, the path name should be the path
        % name of a folder.
        PathName (1,1) string = missing
    end

    methods % Constructor
        
        function obj = StructSerializer(propertyArgs)
            arguments
                propertyArgs.?catalog.serializer.abstract.StructSerializer
            end
            obj.assignPropertyArguments(propertyArgs)
        end
    end

    methods % Set methods for properties
        
        function set.PathName(obj, newValue)
            if newValue == ""
                newValue = missing;
            end
            obj.PathName = newValue;
            obj.onPathNameSet()
            obj.validateFileName()
        end
    end

    methods (Abstract) % Subclasses must implement

        save(obj, structArray, options)

        structArray = load(obj)
    end

    methods (Access = protected) % Subclasses may implement
        
        function onPathNameSet(obj)
            % pass
        end

        function validateFileName(obj)
        % validateFileName - Make sure path name has the correct file extension
            if ismissing(obj.PathName); return; end

            [folderPath, fileName, ext] = fileparts(obj.PathName);

            if ext == "" || ext ~= obj.SerializationFormat
                obj.PathName = fullfile(folderPath, fileName + obj.SerializationFormat);
                warning('Path name has the wrong file extension. Changed to %s', obj.SerializationFormat)
            end
        end
    end
end