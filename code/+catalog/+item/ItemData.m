classdef ItemData < handle & matlab.mixin.indexing.RedefinesParen

    properties (SetAccess = immutable)
        DataType (1,1) string {mustBeMember(DataType, ["table", "struct", ""])} = ""
    end
    
    properties (Access = private)
        ItemsStruct (1,:) struct
        ItemsTable (:,:) table
    end

    properties (Dependent, Hidden)
        Items
    end

    methods
        function obj = ItemData(data)
            
            obj.DataType = class(data);

            if obj.DataType == "struct"
                obj.ItemsStruct = data;
            else
                obj.ItemsTable = data;
            end
        end
    end

    methods 

    end

    methods
        function items = get.Items(obj)
            if obj.DataType == "struct"
                items = obj.ItemsStruct;
            elseif obj.DataType == "table"
                items = obj.ItemsTable;
            else
                error('')
            end
        end
    end
    methods (Access=protected)

        function varargout = parenReference(obj, indexOp)

            if isscalar(indexOp)
                if obj.DataType == "struct"
                    [varargout{1:nargout}] = obj.ItemsStruct.(indexOp);
                else
                    subs = substruct('()', {indexOp.Indices{1}, ':'} );
                    [varargout{1:nargout}] = subsref(obj.ItemsTable, subs);
                end
            else
                intermediateObj = obj.parenReference(indexOp(1));
                [varargout{1:nargout}] = intermediateObj.(indexOp(2:end));
            end

        end
        
        function obj = parenAssign(obj, indexOp, varargin)
            % Ensure object instance is the first argument of call.
            if isempty(obj)
                obj = varargin{1};
            end
            if isscalar(indexOp)
                assert(nargin==3);
                rhs = varargin{1};
                obj.ItemsStruct.(indexOp) = rhs;
                return;
            end
            [obj.(indexOp(2:end))] = varargin{:};
        end

        function n = parenListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2 %??
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        function obj = parenDelete(obj, indexOp)
            if obj.DataType == "struct"
                obj.ItemsStruct.(indexOp) = [];
            else
                obj.ItemsTable(indexOp, :) = [];
            end 
        end
    end

    methods (Access=public)
        function out = cat(dim, varargin)
            numCatArrays = nargin-1;
            newArgs = cell(numCatArrays,1);
            for ix = 1:numCatArrays
                if isa(varargin{ix},'catalog.item.ItemData')
                    newArgs{ix} =  varargin{ix}.Items;
                else
                    error('Wrong type for input value %d', ix);
                end
            end
            out = catalog.item.ItemData(cat(dim,newArgs{:}));
        end

        function varargout = size(obj,varargin)
            if obj.DataType == "struct"
                [varargout{1:nargout}] = size(obj.ItemsStruct,varargin{:});
            else
                [varargout{1:nargout}] = size(obj.ItemsTable,varargin{:});
            end
        end
    end

    methods (Static, Access=public)
        function obj = empty()
            obj = catalog.item.ItemData(struct.empty);
        end
    end
end