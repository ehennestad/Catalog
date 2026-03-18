classdef IsSerializable < handle & catalog.mixin.HasPropertyArgs
% IsSerializable - Mixin providing pluggable serialization format management
%
%   Manages a Serializer object that knows how to read/write structs in a
%   specific format (mat, json). The serializer is selected via the
%   SerializationFormat property and can be accessed by subclasses to
%   perform format-specific I/O.

    properties
        SerializationFormat (1,1) string ...
            {mustBeMember(SerializationFormat, ["mat", "json"])} = "mat"
    end

    properties (SetAccess = private, GetAccess = protected)
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

    methods % Set methods
        function set.SerializationFormat(obj, value)
            obj.SerializationFormat = value;
            obj.updateSerializer();
        end
    end

    methods (Access = private)
        function updateSerializer(obj)
            serializerFunctionName = ...
                obj.SerializerFunctionMap(obj.SerializationFormat);
            obj.Serializer = feval(serializerFunctionName);
        end
    end
end
