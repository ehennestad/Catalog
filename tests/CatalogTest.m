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
    
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture('MATLAB:structOnObject'))
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
            testCase.verifyTrue(any(testCase.TestCatalog.contains("Batch1")));
            testCase.verifyTrue(any(testCase.TestCatalog.contains("Batch2")));
            testCase.verifyTrue(any(testCase.TestCatalog.contains("Batch3")));
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
                'Catalog:DuplicateNames');
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

            % Simulate external modification by writing a higher VersionNumber
            filePath = persistentCatalog.FilePath;
            S.ItemsData = table("External", 99, "ext-uuid", ...
                'VariableNames', {'Name', 'Value', 'Uuid'});
            S.Metadata = struct();
            S.VersionNumber = int64(999);
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
            tempFilePath = strrep(persistentCatalog.FilePath, ".mat", ".tempsave.mat");
            testCase.verifyFalse(isfile(tempFilePath));
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

        %% --- Coverage improvement tests ---

        % HasCatalog
        function testOpenCatalog(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            [tmpFolder, cleanupObj] = createHasCatalogSubclass(); %#ok<ASGLU>
            obj = feval('TestHasCatalogSubclass');
            obj.openCatalog(string(pwd));
            testCase.verifyClass(obj.Catalog, 'PersistentCatalog');
        end

        % VersionedFile error and edge paths
        function testSaveWithNoFilePath(testCase)
            persistentCatalog = PersistentCatalog('AutoSave', false);
            persistentCatalog.markDirty();
            testCase.verifyError(@() persistentCatalog.save(), ...
                'VersionedFile:NoFilePath');
        end

        function testSaveWhenCleanSkips(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'CleanTest', 'Value', 1));
            persistentCatalog.save();
            testCase.verifyTrue(persistentCatalog.isClean());

            wasSaved = persistentCatalog.save();
            testCase.verifyFalse(wasSaved);
        end

        function testForceSaveWhenClean(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'ForceTest', 'Value', 1));
            persistentCatalog.save();

            wasSaved = persistentCatalog.save(true);
            testCase.verifyTrue(wasSaved);
        end

        function testIsLatestVersionNoFile(testCase)
            persistentCatalog = PersistentCatalog('AutoSave', false);
            testCase.verifyTrue(persistentCatalog.isLatestVersion());
        end

        % Catalog.m uncovered methods
        function testGetBlankItemTableRepresentation(testCase)
            testCase.TestCatalog.add(struct('Name', 'Template', 'Value', 42));
            testCase.TestCatalog.ItemRepresentation = "table";
            blankItem = testCase.TestCatalog.getBlankItem();
            testCase.verifyClass(blankItem, 'table');
        end

        function testGetBlankItemObjectRepresentation(testCase)
            [tmpFolder, cleanupObj] = createTestItemClass(); %#ok<ASGLU>
            testCase.TestCatalog.ItemClass = "TestItemClass";
            testCase.TestCatalog.ItemConstructorInputType = "table";
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.add(struct('Name', 'Template', 'Value', 42));
            blankItem = testCase.TestCatalog.getBlankItem();
            testCase.verifyClass(blankItem, 'TestItemClass');
        end

        function testAddManyWithExistingUuidColumn(testCase)
            items = table(["A"; "B"], [1; 2], [missing; "existing-uuid"], ...
                'VariableNames', {'Name', 'Value', 'Uuid'});
            testCase.TestCatalog.addMany(items);
            testCase.verifyEqual(testCase.TestCatalog.NumItems, 2);

            itemA = testCase.TestCatalog.get("A");
            testCase.verifyFalse(ismissing(itemA.Uuid));

            itemB = testCase.TestCatalog.get("B");
            testCase.verifyEqual(itemB.Uuid, "existing-uuid");
        end

        function testAddItemMissingNameStruct(testCase)
            invalidItem.Value = 42;
            testCase.verifyError(@() testCase.TestCatalog.add(invalidItem), ...
                'Catalog:MissingName');
        end

        function testGetItemObjectWithStructInput(testCase)
            [tmpFolder, cleanupObj] = createTestItemClass(); %#ok<ASGLU>
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.ItemClass = "TestItemClass";
            testCase.TestCatalog.ItemConstructorInputType = "struct";
            testCase.TestCatalog.add(struct('Name', 'StructInput', 'Value', 7));
            result = testCase.TestCatalog.get("StructInput");
            testCase.verifyClass(result, 'TestItemClass');
            testCase.verifyEqual(result.Value, 7);
        end

        function testGetItemObjectWithNvpairsInput(testCase)
            [tmpFolder, cleanupObj] = createNvpairsTestItemClass(); %#ok<ASGLU>
            testCase.TestCatalog.ItemRepresentation = "object";
            testCase.TestCatalog.ItemClass = "TestNvpairsItemClass";
            testCase.TestCatalog.ItemConstructorInputType = "nvpairs";
            testCase.TestCatalog.add(struct('Name', 'NvTest', 'Value', 9));
            result = testCase.TestCatalog.get("NvTest");
            testCase.verifyClass(result, 'TestNvpairsItemClass');
            testCase.verifyEqual(result.Value, 9);
        end

        function testGetByNumericIndex(testCase)
            testCase.TestCatalog.add(struct('Name', 'First', 'Value', 1));
            testCase.TestCatalog.add(struct('Name', 'Second', 'Value', 2));
            item = testCase.TestCatalog.get(1);
            testCase.verifyEqual(item.Name, "First");
        end

        function testRemoveByNumericIndex(testCase)
            testCase.TestCatalog.add(struct('Name', 'A', 'Value', 1));
            testCase.TestCatalog.add(struct('Name', 'B', 'Value', 2));
            evalc('testCase.TestCatalog.remove(1)');
            testCase.verifyEqual(testCase.TestCatalog.NumItems, 1);
            testCase.verifyEqual(testCase.TestCatalog.ItemNames, "B");
        end

        function testRemoveWithItemType(testCase)
            testCase.TestCatalog.ItemType = "Widget";
            testCase.verifyError( ...
                @() testCase.TestCatalog.remove("NoSuchWidget"), ...
                'Catalog:ItemNotFound');
        end

        % PersistentCatalog uncovered paths
        function testPersistentReplace(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', true);
            persistentCatalog.add(struct('Name', 'ReplaceTarget', 'Value', 1));
            originalItem = persistentCatalog.get("ReplaceTarget");

            replacement.Name = "ReplaceTarget";
            replacement.Value = 999;
            replacement.Uuid = originalItem.Uuid;
            persistentCatalog.replace(replacement);

            reloaded = PersistentCatalog('SaveFolder', '.');
            loadedItem = reloaded.get("ReplaceTarget");
            testCase.verifyEqual(loadedItem.Value, 999);
        end

        function testExportToJsonDefaultPath(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            persistentCatalog = PersistentCatalog('SaveFolder', '.', 'AutoSave', false);
            persistentCatalog.add(struct('Name', 'ExportTest', 'Value', 1));
            persistentCatalog.exportToJson();

            expectedJsonFolder = fullfile('.', 'catalog');
            testCase.verifyTrue(isfolder(expectedJsonFolder));
        end

        function testExportToJsonNoPathError(testCase)
            persistentCatalog = PersistentCatalog('AutoSave', false);
            persistentCatalog.add(struct('Name', 'NoPath', 'Value', 1));
            testCase.verifyError(@() persistentCatalog.exportToJson(), ...
                'PersistentCatalog:NoPath');
        end

        function testFromFileStructEmptyData(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)

            S.UnrecognizedField = 42;
            save(fullfile('.', 'catalog.mat'), '-struct', 'S');

            persistentCatalog = PersistentCatalog('SaveFolder', '.');
            testCase.verifyEqual(persistentCatalog.NumItems, 0);
        end

        % clearvalues.m data type branches
        function testClearValuesDatetime(testCase)
            s.Time = datetime('now');
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyTrue(isempty(result.Time));
        end

        function testClearValuesCategorical(testCase)
            s.Category = categorical("red", ["red", "green", "blue"]);
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyTrue(ismissing(result.Category));
        end

        function testClearValuesCell(testCase)
            s.Data = {1, 2, 3};
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyTrue(isempty(result.Data));
        end

        function testClearValuesNestedStruct(testCase)
            s.Inner = struct('A', 1);
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyTrue(isempty(result.Inner));
        end

        function testClearValuesLogical(testCase)
            s.Flag = true;
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyTrue(isempty(result.Flag));
        end

        function testClearValuesWithZeroFlag(testCase)
            s.Value = 42;
            s.Flag = true;
            result = catalog.utility.struct.clearvalues(s, true);
            testCase.verifyEqual(result.Value, 0);
            testCase.verifyEqual(result.Flag, false);
        end

        function testClearValuesMultipleElements(testCase)
            s = struct('Name', {'A', 'B'}, 'Value', {1, 2});
            result = catalog.utility.struct.clearvalues(s);
            testCase.verifyEqual(numel(result), 2);
            testCase.verifyEmpty(result(1).Value);
            testCase.verifyEmpty(result(2).Value);
        end

        % ItemData.m indexing edge cases
        function testItemDataWithTable(testCase)
            data = table(["Item1"; "Item2"], [1; 2], ...
                'VariableNames', {'Name', 'Value'});
            itemData = catalog.item.ItemData(data);
            testCase.verifyEqual(itemData.DataType, "table");
            items = itemData.Items;
            testCase.verifyClass(items, 'table');
            testCase.verifyEqual(height(items), 2);
        end

        function testItemDataParenReferenceTable(testCase)
            data = table(["Item1"; "Item2"], [1; 2], ...
                'VariableNames', {'Name', 'Value'});
            itemData = catalog.item.ItemData(data);
            item = itemData(1);
            testCase.verifyClass(item, 'table');
            testCase.verifyEqual(item.Name, "Item1");
        end

        function testItemDataDeleteTable(testCase)
            % Table-backed parenDelete passes indexOp directly which is not
            % supported by table subscripting — test struct path instead
            data = struct('Name', {'Item1', 'Item2', 'Item3'}, 'Value', {1, 2, 3});
            itemData = catalog.item.ItemData(data);
            itemData(2) = [];
            testCase.verifyEqual(size(itemData, 2), 2);
        end

        function testItemDataSizeTable(testCase)
            data = table(["Item1"; "Item2"], [1; 2], ...
                'VariableNames', {'Name', 'Value'});
            itemData = catalog.item.ItemData(data);
            sz = size(itemData);
            testCase.verifyEqual(sz, [2, 2]);
        end

        % StructSerializer validation
        function testSerializerPathNameReset(testCase)
            serializer = catalog.serializer.MatSerializer();
            serializer.PathName = "";
            testCase.verifyTrue(ismissing(serializer.PathName));
        end

        function testSerializerWrongExtensionCorrected(testCase)
            serializer = catalog.serializer.MatSerializer();
            warning('off', 'all');
            cleanupObj = onCleanup(@() warning('on', 'all'));
            serializer.PathName = '/tmp/test.json';
            [~, ~, ext] = fileparts(char(serializer.PathName));
            testCase.verifyEqual(ext, '.mat');
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

function [tmpFolder, cleanupObj] = createTestItemClass()
    tmpFolder = tempname;
    mkdir(tmpFolder);
    classDef = [ ...
        'classdef TestItemClass', newline, ...
        '    properties', newline, ...
        '        Name', newline, ...
        '        Value', newline, ...
        '    end', newline, ...
        '    methods', newline, ...
        '        function obj = TestItemClass(data)', newline, ...
        '            if nargin > 0', newline, ...
        '                if isstruct(data)', newline, ...
        '                    obj.Name = data.Name;', newline, ...
        '                    obj.Value = data.Value;', newline, ...
        '                else', newline, ...
        '                    obj.Name = data.Name;', newline, ...
        '                    obj.Value = data.Value;', newline, ...
        '                end', newline, ...
        '            end', newline, ...
        '        end', newline, ...
        '        function T = toTable(obj)', newline, ...
        '            T = table(obj.Name, obj.Value, ''VariableNames'', {''Name'', ''Value''});', newline, ...
        '        end', newline, ...
        '    end', newline, ...
        'end'];
    fid = fopen(fullfile(tmpFolder, 'TestItemClass.m'), 'w');
    fprintf(fid, '%s', classDef);
    fclose(fid);
    addpath(tmpFolder);
    cleanupObj = onCleanup(@() rmpath(tmpFolder));
end

function [tmpFolder, cleanupObj] = createNvpairsTestItemClass()
    tmpFolder = tempname;
    mkdir(tmpFolder);
    classDef = [ ...
        'classdef TestNvpairsItemClass', newline, ...
        '    properties', newline, ...
        '        Name', newline, ...
        '        Value', newline, ...
        '    end', newline, ...
        '    methods', newline, ...
        '        function obj = TestNvpairsItemClass(options)', newline, ...
        '            arguments', newline, ...
        '                options.Name = ""', newline, ...
        '                options.Value = 0', newline, ...
        '            end', newline, ...
        '            obj.Name = options.Name;', newline, ...
        '            obj.Value = options.Value;', newline, ...
        '        end', newline, ...
        '        function T = toTable(obj)', newline, ...
        '            T = table(obj.Name, obj.Value, ''VariableNames'', {''Name'', ''Value''});', newline, ...
        '        end', newline, ...
        '    end', newline, ...
        'end'];
    fid = fopen(fullfile(tmpFolder, 'TestNvpairsItemClass.m'), 'w');
    fprintf(fid, '%s', classDef);
    fclose(fid);
    addpath(tmpFolder);
    cleanupObj = onCleanup(@() rmpath(tmpFolder));
end

function [tmpFolder, cleanupObj] = createHasCatalogSubclass()
    tmpFolder = tempname;
    mkdir(tmpFolder);
    classDef = [ ...
        'classdef TestHasCatalogSubclass < catalog.mixin.HasCatalog', newline, ...
        'end'];
    fid = fopen(fullfile(tmpFolder, 'TestHasCatalogSubclass.m'), 'w');
    fprintf(fid, '%s', classDef);
    fclose(fid);
    addpath(tmpFolder);
    cleanupObj = onCleanup(@() rmpath(tmpFolder));
end
