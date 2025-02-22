classdef IsSerializable < handle & catalog.mixin.HasPropertyArgs

    % Todo: 
    % [ ] Add yaml serialization
    % [ ] Generalize a way to create name for each item
    % [ ] Serializer should be a public property or there should be a
    %     public method for setting a custom serializer


    properties
        SaveFolder (1,1) string = missing % Todo: Rename to PathName
    
        SerializationFormat (1,1) string ...
            {mustBeMember(SerializationFormat, ["mat", "json"])} = "mat"
    end

    properties (Abstract, Dependent, Access = protected)
        Data
        Names
    end

    properties (Access = private)
        Serializer (1,1) catalog.serializer.abstract.StructSerializer = ...
            catalog.serializer.MatSerializer()
    end

    properties (Access = private)
        SerializerFunctionMap = dictionary(...
             "mat", "catalog.serializer.MatSerializer", ...
            "json", "catalog.serializer.JsonSerializer")
    end

    methods % Constructor
        function obj = IsSerializable(propertyArgs)
            arguments
                propertyArgs.?catalog.mixin.IsSerializable
            end
            obj.assignPropertyArguments(propertyArgs)
        end
    end

    methods % Set methods for properties
        
        function set.SaveFolder(obj, value)
            obj.SaveFolder = value;
            obj.onSaveFolderSet()
        end

        function set.SerializationFormat(obj, value)
            obj.SerializationFormat = value;
            obj.onSerializationFormatSet()
        end
    end

    methods % Save/load methods
        function save(obj)
            if ismissing(obj.SaveFolder)
                error('No file location specified')
            end
            data = table2struct(obj.Data);
            obj.Serializer.save(data, "Names", obj.Names);
        end

        function load(obj)
            if ismissing(obj.SaveFolder)
                error('No file location specified')
            end
            obj.Data = struct2table(obj.Serializer.load());
        end

        function delete(obj, item)
            %todo
        end

        function update(obj, item)
            %todo
        end
    end
    
    methods (Access = private)
        
        function onSaveFolderSet(obj)
            obj.updateSerializer()
        end
        
        function onSerializationFormatSet(obj)
            obj.updateSerializer()
        end

        function updateSerializer(obj)
            serializerFunctionName = ...
                obj.SerializerFunctionMap(obj.SerializationFormat);

            obj.Serializer = feval(serializerFunctionName, ...
                "PathName", obj.SaveFolder);
        end
    end
end