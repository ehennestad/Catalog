classdef PersistentStorage < handle & catalog.mixin.HasPropertyArgs

    % Todo: 
    % [ ] Add yaml serialization
    % [ ] Generalize a way to create name for each item
    % [ ] Serializer should be a public property or there should be a
    %     public method for setting a custom serializer


    properties
        PathName (1,1) string = missing % Todo: Rename to PathName
    
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
        function obj = PersistentStorage(propertyArgs)
            arguments
                propertyArgs.?catalog.mixin.IsSerializable
            end
            obj.assignPropertyArguments(propertyArgs)
        end
    end

    methods % Set methods for properties
        
        function set.PathName(obj, value)
            obj.PathName = value;
            obj.onSaveFolderSet()
        end

        function set.SerializationFormat(obj, value)
            obj.SerializationFormat = value;
            obj.onSerializationFormatSet()
        end
    end

    methods % Save/load methods
        function save(obj)
            if ismissing(obj.PathName)
                error('No file location specified')
            end

            obj.Serializer.save(obj.Data, "Names", obj.Names);
        end

        function load(obj)
            if ismissing(obj.PathName)
                error('No file location specified')
            end
            obj.Data = obj.Serializer.load();
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
                "PathName", obj.PathName);
        end
    end
end