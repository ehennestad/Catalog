classdef Catalog < handle & ...
                   matlab.mixin.CustomDisplay & ...
                   catalog.mixin.HasPropertyArgs

% Catalog - A collection of unique, named and ordered items
%
%   This class is something of a hybrid between a dictionary and a table.
%   The main idea is that it will hold unique items, where an item is a
%   structure or an object with a set of fields (properties). 
%
%   The key differences from a table with row entries:
%       
%       - All items should be named (items can be renamed).
%       - All items will have a universal unique identifier (uuid) which
%         should never change.
%       - Items are ordered (and reorderable) and items can be retrieved by 
%         their row number
% 
%   All manipulation of the data should occur through the methods add,
%   replace, remove. This is to ensure that the identity (uuid) of items 
%   are maintained.


%   Todo:
%   [ ] Add custom sorting of items. Default is to sort by name...
%   [ ] Reorder variables in table display. Name first. Allow specification
%       of row order in a preference property?
%   [ ] Method for adding items in batch.
%   [ ] Consider whether it is a limitation that items need to have unique
%       names. E.g. In a catalog of persons, it might happen that persons 
%       have the same name.
%   [ ] Consider whether to have a Preferences or Configuration property
%       whose value is an object of a Preferences/Configuration class. 
%   [ ] Implement matlab.mixin.indexing.RedefinesParen instead of subsref
%   [ ] Establish a Data + Metadata/Configuration framework.
%   [ ] Implement events, ItemAdded, ItemRemoved, ItemModified

%   Questions.
%   - If items are represented by a class, should we use class property
%   attributes like Hidden and Access to hide variables in the table
%   display

%   Notes:
%       The class uses a table to store data internally.

    % properties (Abstract, Constant)
    %     DEFAULT_ITEM % ??
    % end
    % 
    % properties (Abstract, Constant, Hidden)
    %     ITEM_TYPE           % Name / label for items in catalog
    % end

    properties (Hidden)
        ItemType (1,1) string = missing   % A label / category
        ItemClass (1,1) string = "struct" % Class name
        ItemConstructorInputType (1,1) string ...
            {mustBeMember(ItemConstructorInputType, ["struct", "table", "nvpairs"])} = "table"
    end

    properties
        Description (1,1) string
    end
        
    properties (Dependent, SetAccess = private) % Hidden?
        ItemNames (1,:) string
        NumItems (1,1) double
    end

    properties (Hidden)
        NameField (1,1) string = "Name"
        IDField (1,1) string = "Uuid"
        IgnoreVariables (1,:) string = string.empty
    end

    properties % Catalog preferences
        ItemRepresentation (1,1) string ...
            {mustBeMember(ItemRepresentation, ["struct", "table", "object"])} = "struct"
    end
    
    properties (Access = protected)
        ItemsData (:,:) table
        ObjectCache (1,1) dictionary % Todo: here or subclass?
    end

    properties (Access = private)
        % Whether to show the items as a collapsed or a full table.
        CollapseItemDisplay = true 
    end

    methods (Hidden) % Constructor
        
        function obj = Catalog(data, options)
            arguments
                data = struct.empty % structure array or table
                options.?Catalog
            end
                        
            obj.assignPropertyArguments(options)

            if nargin > 0 && ~isempty(data)
                if isa(data, 'table')
                    obj.ItemsData = data;
                elseif isa(data, 'struct')
                    obj.ItemsData = struct2table(data);
                end
                obj.ensureItemsDataHasUuids()
                obj.assertUniqueItemUUids()
            end
        end
    end

    methods (Access = public) % Public methods

        % Get a blank item from the Catalog
        function blankItem = getBlankItem(obj)
            if obj.NumItems == 0
                warning('CATALOG:NotConfigured', 'Catalog does not have any items yet.')
                return
            end
            item = obj.ItemsData(1,:);
            structItem = table2struct(item);
            blankItem = catalog.utility.struct.clearvalues(structItem);
           
            switch obj.ItemRepresentation
                case 'struct'
                    %pass
                case 'table'
                    blankItem = struct2table(blankItem, "AsArray", true);
                case 'object'
                    blankItem = obj.getItemObject(blankItem);
            end
        end

        % Add a new item to the Catalog
        function newItem = add(obj, newItem)
        
            arguments
                obj (1,1) Catalog       % An object of this class
                newItem (1,:) {mustBeA(newItem, ["struct", "table"])}  % A structure or table representing an item of this class
            end

            if isa(newItem, 'struct')
                newItem = struct2table(newItem);
            end

            % Todo:
            %  Assert that item has all field defined in the default item
            %  Assert that item has a name
            
            name = obj.getItemName(newItem);
            
            if any(strcmp(obj.ItemNames, name))
                error('Catalog:NamedItemExists', ...
                    'An item with the name "%s" already exists', name);  
            end

            idName = obj.IDField;

            if ~isempty(obj.ItemsData)
                if istablevar(newItem, idName)
                    allItemIdentifiers = obj.ItemsData.(idName);
                    newItemIdentifier = newItem.(idName);
                    assert( ~any(strcmp(allItemIdentifiers, newItemIdentifier)), ...
                        'Catalog:UniqueIdentifierExists', ...
                        'An item with the uuid "%s" already exists in the Catalog', newItemIdentifier);
                end
            end

            % Create a uuid
            if ~isfield(newItem, idName)
                newItem.(idName) = string( matlab.lang.internal.uuid );
            end

            % Todo: Reorder fields.

            if isempty(obj.ItemsData) 
                obj.ItemsData = newItem; % Todo: Initialize data using empty item, on first time startup...
            else
                obj.ItemsData(end+1, :) = newItem;
            end

            % Sort items.
            obj.sortItems()

            if ~nargout
                clear newItem
            end
        end
        
        % Get an new item from the Catalog
        function item = get(obj, identifier)
            % Remove name and uuid?
           
            IND = obj.getItemIndex(identifier);
            
            if any(IND)
                item = obj.ItemsData(IND, :);
                item = obj.getOutputRepresentation(item);
            else
                error('Catalog:ItemNotFound', 'No item was found with the given identifier: %s', identifier)
            end
        end

        % Get all the items from the Catalog
        function data = getAll(obj)
            data = obj.getOutputRepresentation(obj.ItemsData);
        end

        % Replace an item in the Catalog
        function newItem = replace(obj, newItem)
            
            % Todo: Error out if Catalog is providing item objects. They
            % should be modified directly...

            % Make sure item has necessary fields...
            % newItem = obj.validateItem(newItem);
            
            % Todo: Replacement should happen using the uuid.

            arguments
                obj
                newItem
            end

            if isa(newItem, 'struct')
                newItem = struct2table(newItem);
            end

            itemName = obj.getItemName(newItem);
            [itemExists, insertIdx] = obj.contains(itemName);

            isMatch = obj.matchesExistingItemIdentifier(newItem);
            
            if ~any(isMatch)
                error('Catalog:ItemNotFound', 'Item with name "%s" does not exist in this catalog. Use the method ''add'' to add a new item to the catalog', itemName)
            else
                if any(itemExists)
                    assert( isequal(insertIdx, find(isMatch)), ...
                        'Can not replace item because an item with the given name already exists, but the uuid is different.')
                end
                obj.ItemsData(isMatch, :) = newItem;
            end

            if ~nargout
                clear newItem
            end
        end

        % Remove an item from the Catalog
        function remove(obj, identifier)
            IND = obj.getItemIndex(identifier);
            if any(IND)
                removedItemName = obj.ItemNames(IND);  % NB: Capture before removal
                obj.ItemsData(IND, :) = [];
                fprintf('"%s" was removed from the catalog.\n', removedItemName)
            else
                if ismissing(obj.ItemType)
                    error('Catalog:ItemNotFound', '"%s" was not found in catalog', identifier)
                else
                    error('Catalog:ItemNotFound', '"%s" was not found in %s catalog', identifier, obj.ItemType)
                end
            end
        end
        
        % Check if an item (based on name) is contained in the Catalog
        function [tf, idx] = contains(obj, itemName)
            tf = ismember(obj.ItemNames, itemName);
            if nargout == 2
                idx = find(tf);
            end
        end
    
        function clearObjectCache(obj)
            obj.ObjectCache = dictionary;
        end
    end

    methods % Get methods for properties
        
        function itemNames = get.ItemNames(obj)
            if isempty(obj.ItemsData)
                itemNames = string.empty;
            else
                itemNames = string( obj.ItemsData.(obj.NameField) );
            end
        end

        function numItems = get.NumItems(obj)
            numItems = height(obj.ItemsData);
        end
    end

    methods (Hidden) % Public access, but not meant for users
        
        function displayCatalogWithAllItems(obj, name)

            import matlab.internal.display.lineSpacingCharacter;
            
            obj.CollapseItemDisplay = false;

            newline = "\n"+lineSpacingCharacter;

            % If display is directly called, no varname is supplied.
            varEquals = sprintf("%s =", name) + newline;
            fprintf(lineSpacingCharacter);
            fprintf(varEquals)
            disp(obj)

            obj.CollapseItemDisplay = true; % Todo: onCleanup instead
        end
    end
    
    methods (Access = protected)
        
        function sortItems(obj)
            [~, idx] = sort(obj.ItemNames);
            obj.ItemsData = obj.ItemsData(idx, :);
        end

        function data = getOutputRepresentation(obj, item)
            switch obj.ItemRepresentation
                case 'struct'
                    data = table2struct(item);
                case 'table'
                    data = item;
                case 'object'
                    data = obj.getItemObject(item);
            end
        end
    end

    methods (Access = private)
        function tf = matchesExistingItemIdentifier(obj, newItem)
            idName = obj.IDField;
            tf = strcmp(obj.ItemsData.(idName), newItem.(idName));
        end

        function idx = getItemIndex(obj, itemName)
            
            if isnumeric(itemName) % Assume index was given instead of name
                idx = itemName;
                
            elseif obj.isuuid(itemName) % Assume uuid was given instead of name
                idx = find(strcmp(obj.ItemsData.(obj.IDField), itemName));
                
            else
                idx = find(strcmp(obj.ItemNames, itemName));
            end
        end

        function name = getItemName(obj, item)
            if istable(item)
                if istablevar(item, obj.NameField)
                    name = item.(obj.NameField);
                else
                    error('Catalog:MissingName', 'The given item table is missing the name column ("%s").', obj.NameField);
                end
            elseif isstruct(item)
                if isfield(item, obj.NameField)
                    name = item.(obj.NameField);
                else
                    error('Catalog:MissingName', 'The given item struct does not have a name field ("%s").', obj.NameField);
                end
            else
                error('Catalog:InvalidItemType', 'Item must be either a struct or a table.');
            end
        end

        function getItemIdentifier(obj, item)

        end
    
        function displayItems(obj, varName)
            titleTxt = sprintf('  <strong>Available Items:</strong>');

            obj.updateItemDataFromObjectCache()

            %T = struct2table(obj.ItemsData, 'AsArray', true);
            T = obj.ItemsData;
            T.Properties.RowNames = arrayfun(@(i) num2str(i), 1:obj.NumItems, 'uni', 0);
            T.(obj.NameField) = string(T.(obj.NameField));
            try %#ok<TRYNC>
                %T = removevars(T, obj.IDField);
            end
            fprintf('%s\n', titleTxt)
            
            if obj.CollapseItemDisplay
                tableStr = evalc('T');
                idx = strfind(tableStr, newline);
                hasFooterLink = numel(regexp(tableStr, '<a href'))==2;
                if hasFooterLink
                    tableStr = tableStr(idx(4)+1:idx(end-3));
                    disp(tableStr)

                    % Create link
                    fprintf('        <a href="matlab:if exist(''%s'',''var'') && isa(%s, ''Catalog''),displayCatalogWithAllItems(%s,''%s''),else,fprintf(''Unable to display catalog variable ''''%s'''' because it no longer exists.''),fprintf(newline);end">Display all items.</a>', varName,varName,varName,varName,varName);
                    fprintf(newline)
                    fprintf(newline)
                else
                    tableStr = tableStr(idx(4)+1:idx(end-1));
                    disp(tableStr)
                end
            else
                disp(T)
                obj.CollapseItemDisplay = true;
            end
        end

        function ensureItemsDataHasUuids(obj)
            if ~istablevar(obj.ItemsData, obj.IDField)
                uuid = arrayfun(@(i) string( matlab.lang.internal.uuid() ), 1:obj.NumItems);
                obj.ItemsData = addvars(obj.ItemsData, uuid', 'NewVariableNames', obj.IDField);
            end
        end
        function assertUniqueItemUUids(obj)
            allIdentifiers = obj.ItemsData.(obj.IDField);
            assert(numel(allIdentifiers) == numel(unique(allIdentifiers)), ...
                'One or more catalog items do not have unique identifiers.')
        end
    
        function itemObjects = getItemObject(obj, items)
            
            assert(~ismissing(obj.ItemClass) && ~strcmp(obj.ItemClass, 'struct'))
            
            itemObjects = cell( 1, height(items) );
            allItemIdentifiers = items.(obj.IDField);

            for i = 1:height(items)
                itemKey = allItemIdentifiers(i);
                if isConfigured(obj.ObjectCache) && isKey(obj.ObjectCache, itemKey )
                    itemObjects{i} = obj.ObjectCache( itemKey );
                else
                    switch obj.ItemConstructorInputType
                        case 'table'
                            itemObjects{i} = feval(obj.ItemClass, items(i,:));
                        case 'struct'
                            itemObjects{i} = feval(obj.ItemClass, table2struct(items(i,:)));
                        case 'nvpairs'
                            s = table2struct(items(i,:)) ;
                            s = rmfield(s, obj.IDField);
                            nvPairs = namedargs2cell( s );
                            itemObjects{i} = feval(obj.ItemClass, nvPairs{:});

                    end
                    obj.ObjectCache( itemKey ) = itemObjects{i};
                end
            end
            itemObjects = cat(2, itemObjects{:});
        end
    
        function updateItemDataFromObjectCache(obj)
            if ~isConfigured(obj.ObjectCache)
                return
            end

            cachedKeys = string( obj.ObjectCache.keys() );

            if isempty(cachedKeys)
                return
            else
                for iKey = 1:numel(cachedKeys)
                    currentKey = cachedKeys(iKey);
                    currentObject = obj.ObjectCache(currentKey);
                    
                    rowIdx = obj.getItemIndex(currentKey);
                    obj.ItemsData(rowIdx, :) = currentObject.toTable();
                end
            end
        end
    end

    methods (Sealed, Access = protected, Hidden) % Overridden display methods
        
        function str = getHeader(obj)
            str = getHeader@matlab.mixin.CustomDisplay(obj);
            if ~ismissing(obj.ItemType)
                str = strrep(str, 'with properties', sprintf('(%s) with properties', obj.ItemType));
            end
        end

        function str = getFooter(obj)

            % Display the items using a tabular display
            if obj.NumItems == 0
                disp('  No Available Items')
            else
                varName = inputname(1);
                obj.displayItems(varName)
            end

            % Build footer string
            str = {};
            if obj.NumItems > 0
                str{end+1} = sprintf('  Use item = %s(rowNumber) to retrieve an item from the catalog', varName);
                str{end+1} = newline;
            end
            str{end+1} = newline;
            str{end+1} = sprintf('  Show %s\n', '<a href="matlab:methods Catalog" style="font-weight:bold">available methods</a>');
        
            str = strjoin(str, '');
        end
    end

    methods (Sealed, Hidden) % Overridden indexing method

        function varargout = subsref(obj, s)
            
            obj.checkForPackagePrefix(s)

            numOutputs = nargout;
            varargout = cell(1, numOutputs);
                        
            if strcmp( s(1).type, '()')
                if numel(s(1).subs) == 1
                    s(1).subs{end+1} = ':';
                end
                item = builtin('subsref', obj.ItemsData, s(1));
                item = obj.getOutputRepresentation(item);
                if numel(s) == 1
                    [varargout{1}] = item;
                else
                    if numOutputs > 0
                        [varargout{:}] = builtin('subsref', item, s(2:end));
                    else
                        builtin('subsref', item, s(2:end))
                    end
                end
            else
                if numOutputs > 0
                    [varargout{:}] = builtin('subsref', obj, s);
                else
                    builtin('subsref', obj, s)
                end
            end
        end
        
        function n = numArgumentsFromSubscript(obj, s, indexingContext)
            if strcmp( s(1).type, '()')
                s(1).subs{end+1} = ':';
                item = builtin('subsref', obj.ItemsData, s(1));
                item = obj.getOutputRepresentation(item);
                n = builtin('numArgumentsFromSubscript', item, s(2:end), indexingContext);
            else
                n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
            end
        end
    end

    methods (Static, Access = private)
        function tf = isuuid(value)
        % isuuid - Check if a string value is a formatted as a uuid
            tf = false;
            
            if ischar(value) || isstring(value)
                expression = '\w{8}-\w{4}-\w{4}-\w{4}-\w{12}';
                tf = ~isempty(regexp(value, expression, 'once'));
            end
        end

        function checkForPackagePrefix(s)
        % checkForPackagePrefix - Sanity check as it is easy to fall for
        % the temptation of calling a variable "catalog"
        
        %   Note: This is an internal method

            isDotReference = arrayfun(@(c) strcmp(c.type, '.'), s );

            persistent packageNames
            if isempty(packageNames)
                rootDir = fileparts(mfilename('fullpath'));
                pathInfo = what(fullfile(rootDir, '+catalog'));
                packageNames = pathInfo.packages;
            end
            
            if isDotReference(1)
                if any( strcmp(s(1).subs, packageNames) )
                    ME = MException('Catalog:InvalidIndexOperation', ...
                        'It appears you are trying to access a package function, but the Catalog class is invoked. If you have any catalog objects in the workspace named "catalog" this error will show. Please make sure no variables are called "catalog" and try again.');
                    throwAsCaller(ME)
                end
            end
        end
    end
end

function tf = istablevar(T, varName)
    tf = any(strcmp(T.Properties.VariableNames, varName));
end
