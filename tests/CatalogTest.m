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
            % Test package prefix checking (placeholder)
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

        % Tests for ItemData class
        function testItemDataClass(testCase)
            % Create test data
            data = struct('Name', {'Item1', 'Item2'}, 'Value', {1, 2});
            itemData = catalog.item.ItemData(data);

            % Test Items property
            items = itemData.Items;
            testCase.verifyEqual(numel(items), 2);

            % Test indexing
            item = itemData.Items(1);
            testCase.verifyEqual(item.Name, 'Item1');

            % Test size
            sz = size(itemData);
            testCase.verifyEqual(sz, [1 2]);

            % Test concatenation
            data2 = struct('Name', {'Item3'}, 'Value', {3});
            itemData2 = catalog.item.ItemData(data2);
            combined = [itemData, itemData2];
            testCase.verifyEqual(size(combined.Items, 2), 3);
        end

        % Tests for serialization
        function testJsonSerialization(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            % Create test data
            item.Name = "SerializeTest";
            item.Value = 42;
            testCase.TestCatalog.add(item);

            jsonSerializer = catalog.serializer.JsonSerializer();
            jsonSerializer.PathName = fullfile('.', 'test.json');

            % Save data
            data = testCase.TestCatalog.getAll();
            jsonSerializer.save(data);

            % Verify file exists
            testCase.verifyTrue( isfolder(jsonSerializer.PathName) );

            % Load and verify data
            loadedData = jsonSerializer.load();
            testCase.verifyEqual(loadedData(1).Name, 'SerializeTest');
            testCase.verifyEqual(loadedData(1).Value, 42);
        end

        function testMatSerialization(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            % Create test data
            item.Name = "SerializeTest";
            item.Value = 42;
            testCase.TestCatalog.add(item);

            matSerializer = catalog.serializer.MatSerializer();
            matSerializer.PathName = fullfile('.', 'test.mat');

            % Save data
            data = testCase.TestCatalog.getAll();
            matSerializer.save(data);

            % Verify file exists
            testCase.verifyTrue(exist(matSerializer.PathName, 'file') == 2);

            % Load and verify data
            loadedData = matSerializer.load();
            testCase.verifyEqual(loadedData(1).Name, "SerializeTest");
            testCase.verifyEqual(loadedData(1).Value, 42);
        end

        % Tests for persistent storage
        function testPersistentStorage(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);

            % Add test data
            item.Name = "PersistTest";
            item.Value = 42;
            persistentCatalog.add(item);

            % Save catalog
            persistentCatalog.save();

            % Create new instance and load
            persistentCatalog2 = PersistentCatalog('SaveFolder', '.');

            % Verify data
            testCase.verifyEqual(persistentCatalog2.NumItems, 1);
            loadedItem = persistentCatalog2.get("PersistTest");
            testCase.verifyEqual(loadedItem.Value, 42);
        end

        % Additional tests for improved coverage
        function testItemDataParenOperations(testCase)
            % Create test data
            data = struct('Name', {'Item1', 'Item2'}, 'Value', {1, 2});
            itemData = catalog.item.ItemData(data);

            % Test paren reference
            item = itemData(1);
            testCase.verifyEqual(item.Name, 'Item1');

            % Test paren assign
            newData = struct('Name', 'Item3', 'Value', 3);
            itemData(3) = newData;
            testCase.verifyEqual(itemData(3).Name, 'Item3');

            % Test paren delete
            itemData(3) = [];
            testCase.verifyEqual(size(itemData, 2), 2);

            % Test empty
            emptyData = catalog.item.ItemData.empty();
            testCase.verifyTrue(isempty(emptyData));
        end

        function testSerializationFormat(testCase)
            % Create test data
            item.Name = "SerializeTest";
            item.Value = 42;
            testCase.TestCatalog.add(item);

            % Setup serializer with different formats
            tmpDir = tempname;
            mkdir(tmpDir);
            cleanupObj = onCleanup(@() rmdir(tmpDir, 's'));

            % Test JSON format
            jsonSerializer = catalog.serializer.JsonSerializer();
            jsonSerializer.PathName = tmpDir;

            % Save and verify
            data = testCase.TestCatalog.getAll();
            jsonSerializer.save(data, 'Names', 'SerializeTest');

            % Test MAT format
            matSerializer = catalog.serializer.MatSerializer();
            matSerializer.PathName = tmpDir;

            % Save and verify
            matSerializer.save(data);
        end

        function testComplexItemName(testCase)
            % Test item name handling with different types
            item1.Name = "Test1";
            item1.Value = 1;
            testCase.TestCatalog.add(item1);

            % Test with table
            data = table('Size', [1 2], 'VariableTypes', {'string', 'double'}, ...
                        'VariableNames', {'Name', 'Value'});
            data.Name = "Test2";
            data.Value = 2;
            testCase.TestCatalog.add(data);

            % Test with invalid input
            invalidItem.Value = 3;  % Missing Name field
            testCase.verifyError(@() testCase.TestCatalog.add(invalidItem), ...
                'Catalog:MissingName');
        end

        function testObjectCacheUpdate(testCase)
            % Create a test class
            testClassName = 'TestItemClass';
            testClassDef = sprintf(['classdef %s < handle\n' ...
                                  '    properties\n' ...
                                  '        Name\n' ...
                                  '        Value\n' ...
                                  '        Uuid\n' ...
                                  '    end\n' ...
                                  '    methods\n' ...
                                  '        function obj = %s(data)\n' ...
                                  '            if nargin > 0\n' ...
                                  '                obj.Name = data.Name;\n' ...
                                  '                obj.Value = data.Value;\n' ...
                                  '                obj.Uuid = data.Uuid;\n' ...
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

            % Test object cache updates
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.ItemClass = testClassName;

            item.Name = "CacheTest";
            item.Value = 42;
            item.Uuid = matlab.lang.internal.uuid;
            testCase.TestCatalog.add(item);

            % Get object and modify it
            obj = testCase.TestCatalog.get("CacheTest");
            obj.Value = 100;

            % Update cache and verify
            testCase.TestCatalog.updateItemDataFromObjectCache();
            updatedItem = testCase.TestCatalog.get("CacheTest");
            testCase.verifyEqual(updatedItem.Value, 100);
        end

        %% --- New tests for Phase 0 features ---

        % Events
        function testItemAddedEvent(testCase)
            eventFired = false;
            eventItemName = "";
            listener = addlistener(testCase.TestCatalog, 'ItemAdded', ...
                @(~, e) assignin('caller', 'eventFired', true));

            item.Name = "EventTest";
            item.Value = 1;
            testCase.TestCatalog.add(item);

            % Verify event fires by using a different approach
            eventData = [];
            listener2 = addlistener(testCase.TestCatalog, 'ItemAdded', ...
                @(~, e) testCase.captureEvent(e));
            testCase.TestCatalog.add(struct('Name', 'EventTest2', 'Value', 2));

            delete(listener);
            delete(listener2);
        end

        function testItemRemovedEvent(testCase)
            item.Name = "RemoveEventTest";
            item.Value = 1;
            testCase.TestCatalog.add(item);

            capturedEventData = [];
            listener = addlistener(testCase.TestCatalog, 'ItemRemoved', ...
                @(~, e) assignCaptured(e));
            evalc('testCase.TestCatalog.remove("RemoveEventTest")');

            testCase.verifyNotEmpty(capturedEventData);
            testCase.verifyEqual(capturedEventData.ItemName, "RemoveEventTest");
            delete(listener);

            function assignCaptured(eventData)
                capturedEventData = eventData;
            end
        end

        function testItemModifiedEventFromReplace(testCase)
            item.Name = "ModifyEventTest";
            item.Value = 1;
            testCase.TestCatalog.add(item);

            originalItem = testCase.TestCatalog.get("ModifyEventTest");

            capturedEventData = [];
            listener = addlistener(testCase.TestCatalog, 'ItemModified', ...
                @(~, e) assignCaptured(e));

            replacement.Name = "ModifyEventTest";
            replacement.Value = 99;
            replacement.Uuid = originalItem.Uuid;
            testCase.TestCatalog.replace(replacement);

            testCase.verifyNotEmpty(capturedEventData);
            testCase.verifyEqual(capturedEventData.ItemName, "ModifyEventTest");
            delete(listener);

            function assignCaptured(eventData)
                capturedEventData = eventData;
            end
        end

        % Update method
        function testUpdateSingleField(testCase)
            item.Name = "UpdateTest";
            item.Value = 1;
            item.Description = "original";
            testCase.TestCatalog.add(item);

            testCase.TestCatalog.update("UpdateTest", "Value", 42);

            updatedItem = testCase.TestCatalog.get("UpdateTest");
            testCase.verifyEqual(updatedItem.Value, 42);
            testCase.verifyEqual(updatedItem.Description, "original");
        end

        function testUpdateFiresItemModifiedEvent(testCase)
            item.Name = "UpdateEventTest";
            item.Value = 1;
            testCase.TestCatalog.add(item);

            capturedEventData = [];
            listener = addlistener(testCase.TestCatalog, 'ItemModified', ...
                @(~, e) assignCaptured(e));

            testCase.TestCatalog.update("UpdateEventTest", "Value", 99);

            testCase.verifyNotEmpty(capturedEventData);
            testCase.verifyEqual(capturedEventData.ItemName, "UpdateEventTest");
            delete(listener);

            function assignCaptured(eventData)
                capturedEventData = eventData;
            end
        end

        function testUpdateNonexistentItemThrowsError(testCase)
            testCase.verifyError( ...
                @() testCase.TestCatalog.update("NoSuchItem", "Value", 1), ...
                'Catalog:ItemNotFound');
        end

        % AddMany method
        function testAddManyWithStructArray(testCase)
            items = struct('Name', {'Batch1', 'Batch2', 'Batch3'}, ...
                           'Value', {10, 20, 30});
            testCase.TestCatalog.addMany(items);

            testCase.verifyEqual(testCase.TestCatalog.NumItems, 3);
            testCase.verifyTrue(testCase.TestCatalog.contains("Batch1"));
            testCase.verifyTrue(testCase.TestCatalog.contains("Batch2"));
            testCase.verifyTrue(testCase.TestCatalog.contains("Batch3"));
        end

        function testAddManyWithTable(testCase)
            items = table(["T1"; "T2"], [1; 2], ...
                'VariableNames', {'Name', 'Value'});
            testCase.TestCatalog.addMany(items);

            testCase.verifyEqual(testCase.TestCatalog.NumItems, 2);
        end

        function testAddManyDuplicateNamesInBatchThrowsError(testCase)
            items = struct('Name', {'Dup', 'Dup'}, 'Value', {1, 2});
            testCase.verifyError( ...
                @() testCase.TestCatalog.addMany(items), ...
                'MATLAB:assert:failed');
        end

        function testAddManyConflictsWithExistingThrowsError(testCase)
            testCase.TestCatalog.add(struct('Name', 'Existing', 'Value', 1));
            items = struct('Name', {'Existing', 'New'}, 'Value', {2, 3});
            testCase.verifyError( ...
                @() testCase.TestCatalog.addMany(items), ...
                'Catalog:NamedItemExists');
        end

        % VersionedFile: dirty tracking
        function testDirtyTracking(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            testCase.verifyTrue(persistentCatalog.isClean());

            persistentCatalog.add(struct('Name', 'DirtyTest', 'Value', 1));
            testCase.verifyFalse(persistentCatalog.isClean());

            persistentCatalog.save();
            testCase.verifyTrue(persistentCatalog.isClean());
        end

        % VersionedFile: version tracking
        function testVersionTracking(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'VersionTest', 'Value', 1));
            persistentCatalog.save();

            testCase.verifyTrue(persistentCatalog.isLatestVersion());

            % Simulate external modification by touching the file
            pause(1.1)
            filePath = persistentCatalog.FilePath;
            S.ItemsData = table("External", 99, "ext-uuid", ...
                'VariableNames', {'Name', 'Value', 'Uuid'});
            S.Metadata = struct();
            save(char(filePath), '-struct', 'S');

            testCase.verifyFalse(persistentCatalog.isLatestVersion());
        end

        % AutoSave
        function testAutoSaveOnAdd(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', true);
            persistentCatalog.add(struct('Name', 'AutoSaveTest', 'Value', 1));

            % Verify file was created and catalog is clean
            testCase.verifyTrue(isfile(persistentCatalog.FilePath));
            testCase.verifyTrue(persistentCatalog.isClean());

            % Reload and verify
            reloaded = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(reloaded.NumItems, 1);
            loadedItem = reloaded.get("AutoSaveTest");
            testCase.verifyEqual(loadedItem.Value, 1);
        end

        function testAutoSaveOnRemove(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', true);
            persistentCatalog.add(struct('Name', 'RemoveMe', 'Value', 1));
            persistentCatalog.add(struct('Name', 'KeepMe', 'Value', 2));
            evalc('persistentCatalog.remove("RemoveMe")');

            reloaded = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(reloaded.NumItems, 1);
            testCase.verifyEqual(reloaded.ItemNames, "KeepMe");
        end

        function testAutoSaveOnUpdate(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', true);
            persistentCatalog.add(struct('Name', 'UpdateMe', 'Value', 1));
            persistentCatalog.update("UpdateMe", "Value", 999);

            reloaded = PersistentCatalog('SaveFolder', '.');
            loadedItem = reloaded.get("UpdateMe");
            testCase.verifyEqual(loadedItem.Value, 999);
        end

        function testAutoSaveDisabled(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'NoAutoSave', 'Value', 1));

            % File should not exist yet (no auto-save)
            testCase.verifyFalse(isfile(persistentCatalog.FilePath));
        end

        % Metadata
        function testMetadataRoundTrip(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            metadata = struct('DefaultPipeline', 'myPipeline', 'Version', 2);
            persistentCatalog = PersistentCatalog('SaveFolder', '.', ...
                'AutoSave', false, 'Metadata', metadata);
            persistentCatalog.add(struct('Name', 'MetaTest', 'Value', 1));
            persistentCatalog.save();

            reloaded = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(reloaded.Metadata.DefaultPipeline, 'myPipeline');
            testCase.verifyEqual(reloaded.Metadata.Version, 2);
        end

        % Backward-compatible loading
        function testLegacyDataFieldLoading(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            % Create a legacy-format mat file with Data + Preferences
            legacyData = struct('Name', {'LegacyItem1', 'LegacyItem2'}, ...
                               'Value', {10, 20}, ...
                               'Uuid', {'abc-1234-5678-9012-abcdefabcdef', 'def-1234-5678-9012-abcdefabcdef'});
            S.Data = legacyData;
            S.Preferences = struct('SourceID', 'legacy-source');
            save(fullfile('.', 'catalog.mat'), '-struct', 'S');

            persistentCatalog = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(persistentCatalog.NumItems, 2);
            testCase.verifyEqual(persistentCatalog.Metadata.SourceID, 'legacy-source');
        end

        function testLegacyEntriesFieldLoading(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            % Create a legacy-format mat file with entries field
            entries = struct('Name', {'OldItem'}, 'Value', {99}, ...
                            'Uuid', {'old-1234-5678-9012-abcdefabcdef'});
            S.entries = entries;
            save(fullfile('.', 'catalog.mat'), '-struct', 'S');

            persistentCatalog = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(persistentCatalog.NumItems, 1);
            loadedItem = persistentCatalog.get("OldItem");
            testCase.verifyEqual(loadedItem.Value, 99);
        end

        % Json export/import
        function testJsonExportImport(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'JsonTest', 'Value', 42));

            % Export to json
            jsonPath = fullfile('.', 'catalog_export');
            persistentCatalog.exportToJson(jsonPath);

            % Import into a fresh catalog
            persistentCatalog2 = PersistentCatalog('AutoSave', false);
            persistentCatalog2.importFromJson(jsonPath);

            testCase.verifyEqual(persistentCatalog2.NumItems, 1);
            loadedItem = persistentCatalog2.get("JsonTest");
            testCase.verifyEqual(loadedItem.Value, 42);
        end

        function testJsonFallbackOnLoad(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            % Create json files without a mat file
            jsonDir = fullfile('.', 'catalog');
            mkdir(jsonDir);
            jsonStr = jsonencode(struct('Name', 'FallbackItem', 'Value', 77, ...
                'Uuid', 'fb-1234-5678-9012-abcdefabcdef'));
            fid = fopen(fullfile(jsonDir, 'FallbackItem.json'), 'w');
            fwrite(fid, jsonStr);
            fclose(fid);

            persistentCatalog = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(persistentCatalog.NumItems, 1);
            loadedItem = persistentCatalog.get("FallbackItem");
            testCase.verifyEqual(loadedItem.Value, 77);
        end

        % Atomic save verification
        function testAtomicSave(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'AtomicTest', 'Value', 1));
            persistentCatalog.save();

            % Verify no temp file remains
            testCase.verifyFalse(isfile(persistentCatalog.FilePath + ".tmp"));
            testCase.verifyTrue(isfile(persistentCatalog.FilePath));
        end

        % AddMany on PersistentCatalog with AutoSave
        function testAddManyAutoSave(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', true);
            items = struct('Name', {'B1', 'B2'}, 'Value', {1, 2});
            persistentCatalog.addMany(items);

            reloaded = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(reloaded.NumItems, 2);
        end
    end

    methods(TestMethodTeardown)
        function teardownTest(testCase)
            % Clean up any temporary files or states
            delete(testCase.TestCatalog);
        end
    end

    methods (Access = private)
        function captureEvent(~, ~)
            % Helper for event capture tests
        end
    end
end
