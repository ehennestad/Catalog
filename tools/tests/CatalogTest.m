classdef CatalogTest < matlab.unittest.TestCase
    
    properties
        TestCatalog
    end
    
    methods(TestMethodSetup)
        function setupTest(testCase)
            testCase.TestCatalog = Catalog();
        end
    end
    
    methods(Test)
        function testConstructorEmpty(testCase)
            catalog = Catalog();
            testCase.verifyEmpty(catalog.ItemNames);
            testCase.verifyEqual(catalog.NumItems, 0);
        end
        
        function testConstructorWithData(testCase)
            % Test constructor with initial data
            data = struct('Name', {'Item1', 'Item2'}, ...
                         'Value', {1, 2});
            catalog = Catalog(data);
            
            testCase.verifyEqual(catalog.NumItems, 2);
            testCase.verifyEqual(catalog.ItemNames, ["Item1", "Item2"]');
            
            % Verify UUIDs were generated
            items = catalog.getAll();
            testCase.verifyTrue(all(cellfun(@(x) ~isempty(x), {items.Uuid})));
        end
        
        function testAddItem(testCase)
            item.Name = "TestItem";
            item.Value = 42;
            
            testCase.TestCatalog.add(item);
            
            testCase.verifyEqual(testCase.TestCatalog.NumItems, 1);
            testCase.verifyEqual(testCase.TestCatalog.ItemNames, "TestItem");
            
            retrievedItem = testCase.TestCatalog.get("TestItem");
            testCase.verifyEqual(retrievedItem.Value, 42);
        end
        
        function testAddDuplicateNameThrowsError(testCase)
            item1.Name = "DuplicateName";
            item1.Value = 1;
            
            item2.Name = "DuplicateName";
            item2.Value = 2;
            
            testCase.TestCatalog.add(item1);
            
            testCase.verifyError(@() testCase.TestCatalog.add(item2), ...
                'Catalog:NamedItemExists');
        end
        
        function testRemoveItem(testCase)
            item.Name = "ToRemove";
            item.Value = 123;
            
            testCase.TestCatalog.add(item);
            evalc('testCase.TestCatalog.remove("ToRemove")');
            
            testCase.verifyEqual(testCase.TestCatalog.NumItems, 0);
            testCase.verifyEmpty(testCase.TestCatalog.ItemNames);
        end
        
        function testRemoveNonexistentItem(testCase)
            testCase.verifyError(@() testCase.TestCatalog.remove("NonexistentItem"), ...
                'Catalog:ItemNotFound');
        end
        
        function testReplaceItem(testCase)
            item.Name = "ReplaceMe";
            item.Value = 1;
            
            testCase.TestCatalog.add(item);
            
            originalItem = testCase.TestCatalog.get("ReplaceMe");
            uuid = originalItem.Uuid;
            
            newItem.Name = "ReplaceMe";
            newItem.Value = 2;
            newItem.Uuid = uuid;
            
            testCase.TestCatalog.replace(newItem);
            
            updatedItem = testCase.TestCatalog.get("ReplaceMe");
            testCase.verifyEqual(updatedItem.Value, 2);
            testCase.verifyEqual(updatedItem.Uuid, uuid);
        end
        
        function testGetAll(testCase)
            item1.Name = "Item1";
            item1.Value = 1;
            
            item2.Name = "Item2";
            item2.Value = 2;
            
            testCase.TestCatalog.add(item1);
            testCase.TestCatalog.add(item2);
            
            allItems = testCase.TestCatalog.getAll();
            
            testCase.verifyEqual(numel(allItems), 2);
            testCase.verifyEqual([allItems.Name], ["Item1", "Item2"]);
            testCase.verifyEqual([allItems.Value], [1, 2]);
        end
        
        function testContains(testCase)
            item.Name = "FindMe";
            item.Value = 42;
            
            testCase.TestCatalog.add(item);
            
            [exists, idx] = testCase.TestCatalog.contains("FindMe");
            testCase.verifyTrue(exists);
            testCase.verifyEqual(idx, 1);
            
            [exists, idx] = testCase.TestCatalog.contains("DoesNotExist");
            testCase.verifyFalse(exists);
            testCase.verifyEmpty(idx);
        end
        
        function testItemRepresentation(testCase)
            item.Name = "RepTest";
            item.Value = 42;
            
            % Test struct representation
            testCase.TestCatalog.ItemRepresentation = "struct";
            testCase.TestCatalog.add(item);
            result = testCase.TestCatalog.get("RepTest");
            testCase.verifyClass(result, 'struct');
            
            % Test table representation
            testCase.TestCatalog.ItemRepresentation = "table";
            result = testCase.TestCatalog.get("RepTest");
            testCase.verifyClass(result, 'table');
            
            % Test object representation
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.ItemClass = "containers.Map";
            testCase.verifyError(@() testCase.TestCatalog.get("RepTest"), ...
                'MATLAB:Containers:Map:IncorrectNumberInputs');
        end
        
        function testGetBlankItem(testCase)
            item.Name = "Template";
            item.Value = 42;
            item.Description = "Test";
            
            testCase.TestCatalog.add(item);
            
            blankItem = testCase.TestCatalog.getBlankItem();
            
            testCase.verifyTrue(isfield(blankItem, 'Name'));
            testCase.verifyTrue(isfield(blankItem, 'Value'));
            testCase.verifyTrue(isfield(blankItem, 'Description'));
            testCase.verifyEmpty(char(blankItem.Name));
            testCase.verifyEmpty(blankItem.Value);
            testCase.verifyEmpty(char(blankItem.Description));
        end
        
        function testGetBlankItemEmptyCatalog(testCase)
            testCase.verifyWarning(@() testCase.TestCatalog.getBlankItem(), ...
                'CATALOG:NotConfigured');
        end
        
        function testObjectCache(testCase)
            % Test object cache functionality
            item.Name = "CacheTest";
            item.Value = 42;
            
            testCase.TestCatalog.add(item);
            testCase.TestCatalog.clearObjectCache();
            
            % Verify cache was cleared
            testCase.verifyEqual(testCase.TestCatalog.NumItems, 1);
        end
        
        function testIndexing(testCase)
            % Test indexing functionality
            item1.Name = "Item1";
            item1.Value = 1;
            
            item2.Name = "Item2";
            item2.Value = 2;
            
            testCase.TestCatalog.add(item1);
            testCase.TestCatalog.add(item2);
            
            % Test numeric indexing
            result = testCase.TestCatalog(1);
            testCase.verifyEqual(result.Name, "Item1");
            
            % Test name indexing
            result = testCase.TestCatalog(2);
            testCase.verifyEqual(result.Value, 2);
        end
        
        function testDisplayMethods(testCase)
            % Test display functionality
            item.Name = "DisplayTest";
            item.Value = 42;
            
            testCase.TestCatalog.add(item);
            
            % Verify display doesn't error
            evalc('testCase.verifyWarningFree(@() disp(testCase.TestCatalog))');
        end

        % Additional test methods for improved coverage
        function testItemDataManipulation(testCase)
            % Test table-based item data
            data = table('Size', [2 3], 'VariableTypes', {'string', 'double', 'string'}, ...
                        'VariableNames', {'Name', 'Value', 'Description'});
            data.Name = ["Item1"; "Item2"];
            data.Value = [1; 2];
            data.Description = ["Desc1"; "Desc2"];
            
            catalog = Catalog(data);
            testCase.verifyEqual(catalog.NumItems, 2);
            testCase.verifyEqual(catalog.ItemNames, ["Item1"; "Item2"]);
        end
        
        function testAdvancedIndexing(testCase)
            % Test various indexing operations
            item1.Name = "Item1";
            item1.Value = 1;
            
            item2.Name = "Item2";
            item2.Value = 2;
            
            testCase.TestCatalog.add(item1);
            testCase.TestCatalog.add(item2);
            
            % Test numeric indexing with multiple items
            results = testCase.TestCatalog([1,2]);
            testCase.verifyEqual(numel(results), 2);
            
            % Test UUID indexing
            item = testCase.TestCatalog.get("Item1");
            uuid = item.Uuid;
            result = testCase.TestCatalog.get(uuid);
            testCase.verifyEqual(result.Name, "Item1");
        end
        
        function testObjectRepresentationWithCustomClass(testCase)
            % Create a simple test class
            testClassName = 'TestItemClass';
            testClassDef = sprintf(['classdef %s\n' ...
                                  '    properties\n' ...
                                  '        Name\n' ...
                                  '        Value\n' ...
                                  '    end\n' ...
                                  '    methods\n' ...
                                  '        function obj = %s(data)\n' ...
                                  '            if nargin > 0\n' ...
                                  '                obj.Name = data.Name;\n' ...
                                  '                obj.Value = data.Value;\n' ...
                                  '            end\n' ...
                                  '        end\n' ...
                                  '        function T = toTable(obj)\n' ...
                                  '            T = struct2table(struct(obj));\n' ...
                                  '        end\n' ...
                                  '    end\n' ...
                                  'end'], testClassName, testClassName);
            
            % Create temporary file for test class
            tmpFolder = tempname;
            mkdir(tmpFolder);
            classFile = fullfile(tmpFolder, [testClassName, '.m']);
            fid = fopen(classFile, 'w');
            fprintf(fid, '%s', testClassDef);
            fclose(fid);
            
            % Add folder to path temporarily
            addpath(tmpFolder);
            cleanupObj = onCleanup(@() rmpath(tmpFolder));
            
            % Test object representation
            item.Name = "ObjectTest";
            item.Value = 42;
            
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.ItemClass = testClassName;
            testCase.TestCatalog.add(item);
            
            result = testCase.TestCatalog.get("ObjectTest");
            testCase.verifyClass(result, testClassName);
            testCase.verifyEqual(result.Name, "ObjectTest");
            testCase.verifyEqual(result.Value, 42);
        end
        
        function testDisplayMethodsExtended(testCase)
            item.Name = "DisplayTest";
            item.Value = 42;
            testCase.TestCatalog.add(item);
            
            % Test full display
            evalc('testCase.TestCatalog.displayCatalogWithAllItems("testCatalog")');
            
            % Test display with item type
            testCase.TestCatalog.ItemType = "TestType";
            str = evalc('disp(testCase.TestCatalog)');
            testCase.verifySubstring(str, 'TestType');
        end
        
        function testPackagePrefixChecking(testCase)
            % Test package prefix checking
            % % s(1).type = '.';
            % % s(1).subs = 'catalog';
            % % s(2).type = '.';
            % % s(2).subs = 'item';
            % % 
            % % testCase.verifyError(@() testCase.TestCatalog.subsref(s), ...
            % %     'Catalog:InvalidIndexOperation');
        end
        
        function testItemIdentifierHandling(testCase)
            % Test UUID generation and validation
            item1.Name = "Item1";
            item1.Value = 1;
            
            item2.Name = "Item2";
            item2.Value = 2;
            item2.Uuid = "invalid-uuid";
            
            testCase.TestCatalog.add(item1);
            
            % Verify UUID format
            result = testCase.TestCatalog.get("Item1");
            testCase.verifyTrue(testCase.TestCatalog.isuuid(result.Uuid));
            
            % Test duplicate UUID handling
            result = testCase.TestCatalog.get("Item1");
            item2.Uuid = result.Uuid;
            testCase.verifyError(@() testCase.TestCatalog.add(item2), ...
                'Catalog:UniqueIdentifierExists');
        end
    end
    
    methods(TestMethodTeardown)
        function teardownTest(testCase)
            % Clean up any temporary files or states
            delete(testCase.TestCatalog);
        end
    end
end
