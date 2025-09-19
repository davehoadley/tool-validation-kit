classdef PixelDatastoreTests < matlab.unittest.TestCase
    % PIXELDATASTORETESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties
        ImageSource
        LabelSource
        LabelSourceComplemented
    end %properties

    %% Test Class Setup Methods
    methods(TestClassSetup)
        function setupData(test)

            isource = dir(fullfile(mfilename('fullpath'),'small_test_set', 'images','*.jpg'));
            lsource = dir(fullfile(mfilename('fullpath'),'small_test_set', 'labels','*.png'));
            lcsource = dir(fullfile(mfilename('fullpath'),'small_test_set', 'labels_complemented','*.png'));

            test.ImageSource = fullfile(isource(1).folder, {isource(:).name}');
            test.LabelSource = fullfile(lsource(1).folder, {lsource(:).name}');
            test.LabelSourceComplemented = fullfile(lcsource(1).folder, {lsource(:).name}');
            
        end %function
    end %methods

    %% Test Methods
    methods(Test, TestTags = {'PixelLabelDatastoreTests'})

        function pixelLabelDSCountEachLabelTest(test)
            location = test.LabelSource;
            % Add unused class to test ImagePixelCount
            classes = ["triangle", "background", "unused"];
            values = [255 0 1];
            pxds = pixelLabelDatastore(location, classes, values);

            % Read datastore completely. countEachlabel should work on a
            % copy so it should still work if hasdata(pxds) is false.
            data = {};
            triangleCount = 0;
            bgCount = 0;
            imgPixelCount = 0;
            while hasdata(pxds)
                data(end+1) = read(pxds); %#ok<*AGROW> 

                triangleCount = triangleCount + sum(sum(data{end} == 'triangle'));

                bgCount = bgCount + sum(sum(data{end} == 'background'));

                % all classes have same img pixel count because every image
                % contains all classes.
                imgPixelCount = imgPixelCount + numel(data{end});
            end

            tbl = pxds.countEachLabel();

            test.verifyEqual(tbl.Properties.VariableNames, {'Name', 'PixelCount','ImagePixelCount'});

            test.verifyEqual(height(tbl), numel(pxds.ClassNames));

            test.verifyEqual(tbl.PixelCount(1), triangleCount);
            test.verifyEqual(tbl.PixelCount(2), bgCount);
            test.verifyEqual(tbl.PixelCount(3), 0);
            test.verifyEqual(tbl.ImagePixelCount(1), imgPixelCount);
            test.verifyEqual(tbl.ImagePixelCount(2), imgPixelCount);
            test.verifyEqual(tbl.ImagePixelCount(3), 0);

        end

        function pixelLabelDSHasDataTest(test)
            location = test.LabelSource;
            classes = ["triangle", "background"];
            values = [255 0];
            pxds = pixelLabelDatastore(location, classes, values);

            test.verifyClass(hasdata(pxds),'logical')

            for i = 1:numel(pxds.Files)
                test.verifyTrue(hasdata(pxds))
                [~] = read(pxds);
            end
            test.verifyTrue(~hasdata(pxds))
        end

        %------------------------------------------------------------------
        function pixelLabelDSCanReadImageTest(test)
            location = test.LabelSource;
            classes = ["triangle", "background"];
            values = [255 0];
            pxds = pixelLabelDatastore(location, classes, values);
            pxds.ReadSize = 1;

            % Read the second to last image
            numFiles = numel(pxds.Files);
            idx = max(1, numFiles - 1);
            C_exp = readimage(pxds, idx);

            pxds.reset();
            i = 0;
            while hasdata(pxds)
                i = i + 1;
                C_act = read(pxds);
                if (i == idx)
                    break
                end
            end
            test.verifyTrue(isequal(C_act{1}, C_exp));
            
        end
        
        function pixelLabelImageDSCanCallPartitionByIndexTest(test)
            % partitionByIndex is called in multi-gpu and parallel execution
            % enviorments.
            imds = imageDatastore(test.ImageSource);
            classes = ["triangle", "background"];
            values  = [255 0];
            pxds = pixelLabelDatastore(test.LabelSource, classes, values);
            
            dataStore = pixelLabelImageDatastore(imds, pxds, 'OutputSize', [228 228], 'OutputSizeMode','randcrop');
            dataStore.MiniBatchSize = 4;
            dsnew = partitionByIndex(dataStore,1:8);
            
            % Verify that partitioned version of datastore maintains same
            % property state as original datastore
            test.verifyEqual(dsnew.DataAugmentation, dataStore.DataAugmentation);
            test.verifyEqual(dsnew.ColorPreprocessing, dataStore.ColorPreprocessing);
            test.verifyEqual(dsnew.OutputSize, dataStore.OutputSize);
            test.verifyEqual(dsnew.OutputSizeMode, dataStore.OutputSizeMode);
            
            % Verify that partitionByIndex yields same data as intial
            % version.
            [data,info] = read(dataStore);
            [dataPart,infoPart] = read(dsnew);
            
            % serialize the data for report generation simplicity
            dataIn = data.inputImage;
            dataPartIn = data.inputImage;
            dataPixelLabelImage = data.pixelLabelImage;
            dataPartPixelLabelImage = dataPart.pixelLabelImage;

            if any(size(dataIn) ~= size(dataPartIn)) || any(size(dataPixelLabelImage) ~= size(dataPartPixelLabelImage))
                test.verifyEqual(data,dataPart,'Data sizes from partitioned datastore not equal to original datastore');
            else
                test.verifyEqual(info,infoPart,'Info from partitioned datastore not equal to original datastore');
                for idx = 1:numel(dataIn)
                    dataIn{idx} = dataIn{idx}(:);
                    dataPartIn{idx} = dataPartIn{idx}(:);
                    test.verifyEqual(dataIn{idx},dataPartIn{idx},'input Images from partitioned datastore not equal to original datastore');
                    dataPixelLabelImage{idx} = dataPixelLabelImage{idx}(:);
                    dataPartPixelLabelImage{idx} = dataPartPixelLabelImage{idx}(:);
                    test.verifyEqual(dataPixelLabelImage{idx}, dataPartPixelLabelImage{idx}, 'Pixel label images from partitioned datastore not equal to original datastore');
                end
            end
            
            % second next call should match as well
            [data, info] = read(dataStore);
            [dataPart, infoPart] = read(dsnew);
            
            dataIn = data.inputImage;
            dataPartIn = data.inputImage;
            dataPixelLabelImage = data.pixelLabelImage;
            dataPartPixelLabelImage = dataPart.pixelLabelImage;

            if any(size(dataIn) ~= size(dataPartIn)) || any(size(dataPixelLabelImage) ~= size(dataPartPixelLabelImage))
                test.verifyEqual(data,dataPart,'Data sizes from partitioned datastore not equal to original datastore');
            else
                test.verifyEqual(info,infoPart,'Info from partitioned datastore not equal to original datastore');
                for idx = 1:numel(dataIn)
                    dataIn{idx} = dataIn{idx}(:);
                    dataPartIn{idx} = dataPartIn{idx}(:);
                    test.verifyEqual(dataIn{idx},dataPartIn{idx},'input Images from partitioned datastore not equal to original datastore');
                    dataPixelLabelImage{idx} = dataPixelLabelImage{idx}(:);
                    dataPartPixelLabelImage{idx} = dataPartPixelLabelImage{idx}(:);
                    test.verifyEqual(dataPixelLabelImage{idx}, dataPartPixelLabelImage{idx}, 'Pixel label images from partitioned datastore not equal to original datastore');
                end
            end
            
            % partitionByIndex should reset state
            while hasdata(dataStore)
                [~] = dataStore.read();
            end
            test.assertFalse(hasdata(dataStore));
            
            p = dataStore.partitionByIndex(1:8);
            test.verifyTrue(hasdata(p));
        end
        
        function pixelLabelImageDSCountEachLabelTest(test)
            name = {'triangle';'background'};
            type = repelem(labelType.PixelLabel, 2, 1);
            ids = {255; 0};
            labelDefs = table(name, type, ids, ...
                'VariableNames', {'Name', 'Type', 'PixelLabelID'});
            
            data = groundTruthDataSource(test.ImageSource);
            ldata = table(test.LabelSource, 'VariableNames', {'PixelLabelData'});
            gTruth = groundTruth(data, labelDefs, ldata);
            
            imds = imageDatastore(test.ImageSource);
            pxds = pixelLabelDatastore(gTruth);
            
            g = iCreateDatasourceFromIMDS(imds,pxds);
            
            tbl = countEachLabel(g);
            
            expectedTbl = pxds.countEachLabel();
            
            test.verifyEqual(tbl, expectedTbl);
        end
        
        function pixelLabelImageDSResetTest(test)
            imds = imageDatastore(test.ImageSource);
            classes = ["triangle", "background"];
            values  = [255 0];
            pxds = pixelLabelDatastore(test.LabelSource, classes, values);
            
            dataStore = pixelLabelImageDatastore(imds, pxds, 'OutputSize', [228 228], 'OutputSizeMode','randcrop');
            dataStore.MiniBatchSize = 1;
            for idx = 1:length(imds.Files)
                test.verifyTrue(dataStore.hasdata());
                read(dataStore);
            end
            dataStore.reset();
            
            test.verifyTrue(dataStore.hasdata());
            
            % Perform read operation twice
            for i = 1:2
                act = dataStore.read();
            end
            
            % Read 2nd image
            exp = readByIndex(dataStore,2);
            
            test.verifyTrue(isequal(act,exp));
        end
        
        function pixelLabelImageDSTestPreviewTest(test)
            imds = imageDatastore(test.ImageSource);
            classes = ["triangle", "background"];
            values  = [255 0];
            pxds = pixelLabelDatastore(test.LabelSource, classes, values);
            
            dataStore = pixelLabelImageDatastore(imds, pxds, 'OutputSize', [228 228], 'OutputSizeMode','randcrop');
            dataStore.MiniBatchSize = 1;
            
            firstFileExp = readByIndex(dataStore,1);
            
            for i = 1:4
                [~]  = dataStore.read();
            end
            
            previewFile = preview(dataStore);% Get preview of data
            test.verifyTrue(isequal(previewFile,firstFileExp))
        end
        

    end %methods
end %classdef

%% Local Functions
function g = iCreateDatasourceFromIMDS(imds,pxds, sz)
% Create and start datasource.
g = pixelLabelImageDatastore(imds,pxds);
if nargin==3
    g.MiniBatchSize = sz;
else
    g.MiniBatchSize = 1;
end
g.reset();
end