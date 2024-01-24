classdef PersistentCatalog < Catalog & catalog.mixin.IsSerializable
% PersistentCatalog - A catalog which is stored on the file system
%
%   This class use a serializer to retrieve and update a Catalog stored
%   in a file system. Currently, Catalogs can be saved to mat- or 
%   json-files

%   Questions:
%       Should all changes be immediately saved?
%   

    properties (Dependent, Access = protected)
        Data % Link Catalog ItemsData property to IsSerializable Data property.
        Names
    end

    methods % Constructor
        function obj = PersistentCatalog(superPropertyArgs)
            arguments
                superPropertyArgs.?catalog.mixin.IsSerializable
            end
            nvPairs = namedargs2cell(superPropertyArgs);
            obj = obj@catalog.mixin.IsSerializable(nvPairs{:});

            % Todo: Build filename

            % Load catalog
            if ~ismissing(obj.SaveFolder)
                obj.load()
            end
        end
    end
    
    % Todo: Override methods to save catalog on changes.
    methods
        
    end

    methods
        function data = get.Data(obj)
            data = obj.ItemsData;
        end
        function set.Data(obj, data)
            obj.ItemsData = data;
        end
        function names = get.Names(obj)
            names = obj.ItemNames;
        end
    end
end