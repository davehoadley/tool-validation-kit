classdef SemanticSegTests < matlab.unittest.TestCase
    % SEMANTICSEGTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties
        TriangleNet
        TriangleDAGNet
        MultiChannelDAGNet
        Triangle3DNet
    end
    
    properties(TestParameter)
        verbose = {false,true};
        inputBasedOnDims = iGetParamsBasedOnNDims();
        multiImageSizes = iGetInput();
        isdlnetwork = {false, true};
        outputType = {'categorical','double','uint8'};
    end
    methods
        function env = getExeEnv(~)
            env = 'cpu';
        end
    end
    
    %% Test Class Setup Methods
    methods(TestClassSetup)
        function loadNet(test)
            
            loaded = load('dsegnetDAG.mat');
            test.TriangleDAGNet = loaded.net;
            
            loaded = load('dNetMultispectralDAGNet.mat');
            test.MultiChannelDAGNet = loaded.net;
            
            loaded = load('dTriangleConvTransposeNet.mat');
            test.TriangleNet = loaded.net;
            
            loaded = load('d3dNet.mat');
            test.Triangle3DNet = loaded.net;
            
        end
    end
    
    %% Test Methods
    methods(Test)
        function canSegmentUsingDAGNetwork(test, isdlnetwork)
            % SHOULD be able to run given trained DAGNetwork
            I = imread('triangleTest.jpg');
            
            test.assertClass(test.TriangleDAGNet,'DAGNetwork');
            net = test.TriangleDAGNet;
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            
            [C, ~, ~] = semanticseg(I, net, 'ExecutionEnvironment', getExeEnv(test));
            
            % verify we get expected number of pixels classified as
            % triangles. This is after visual verification of results.
            v = countcats(C(:));
            test.verifyGreaterThan(v(1)/sum(v), 0.36);
        end        
        
        function canSegmentASingleImage(test, inputBasedOnDims, isdlnetwork)
            % SHOULD return categorical, scores, allScores
            I = imread('triangleImages/image_1.jpg');
            I = repmat(I, [1 1 inputBasedOnDims.depth]);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end
            [C, scores, allScores] = semanticseg(I, trainedNet, 'ExecutionEnvironment', getExeEnv(test));
            
            test.verifyEqual(size(C), size(scores));
            
            [predictInput, classes] = iGetPredictInputAndClasses(trainedNet, I, isdlnetwork);
            
            % allScores SHOULD equal result of calling predict. And
            % allScores SHOULD sum to 1 along third dim
            
            predictScores = predict(trainedNet, predictInput);
            if isdlarray(predictScores)
                predictScores = extractdata(predictScores);
            end
            % Need to use verifyTrue since too many values will get printed
            % out in report
            test.verifyTrue(all(ismembertol(allScores, predictScores, single(1e-5)), 'all'))
            test.verifyTrue(all(ismembertol(sum(allScores,inputBasedOnDims.concatInDim-1), ...
                ones(size(scores), 'single'), single(1e-6)), "all"));
            
            % categories in C SHOULD match layer's class names.
            test.verifyEqual(categories(C), classes);
            
            
            % Grayscale net SHOULD work with RGB image for 2D and error for
            % 3D
            if isdlnetwork
                errorId = 'nnet_cnn:internal:cnn:layer:util:InputValidationStrategy:WrongNumberChannels';
            else
                errorId = 'nnet_cnn:DAGNetwork:WrongSizePredictDataForImageInputLayer';
            end
            rgb = cat(inputBasedOnDims.concatInDim-1 ,I, I, I);
            if inputBasedOnDims.is3D
                test.verifyError(@()testRGB(), errorId);
            else
                test.verifyWarningFree(@()testRGB());
            end
            
            function testRGB()
                [~,~,~] = semanticseg(rgb, trainedNet, 'ExecutionEnvironment', getExeEnv(test));
            end
        end
        
        function canSegmentMultiChannelImage(test, isdlnetwork)
            % SHOULD return categorical, scores, allScores
            loaded = load('multiSpectralImages/hamlin_beach_tile_1.mat');
            I1 = loaded.I1;
            loaded = load('multiSpectralImages/hamlin_beach_tile_2.mat');
            I2 = loaded.I2;
            loaded = load('multiSpectralImages/hamlin_beach_tile_3.mat');
            I3 = loaded.I3;
            
            net = test.MultiChannelDAGNet;
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            
            [C, scores, allScores] = semanticseg(I1, net,...
                'ExecutionEnvironment', getExeEnv(test));
            
            test.verifyEqual(size(C), size(scores));
            
            [predictInput, classes] = iGetPredictInputAndClasses(net, I1, isdlnetwork);
            
            % allScores SHOULD equal result of calling predict. And
            % allScores SHOULD sum to 1 along third dim
            predictScores = predict(net, predictInput);
            if isdlnetwork
                predictScores = extractdata(predictScores);
            end
            test.verifyTrue(all(ismembertol(allScores, predictScores, single(1e-5)), 'all'))
            test.verifyTrue(all(ismembertol(sum(allScores,3), ...
                ones(size(scores), 'single'), single(1e-6)), "all"));
            
            % categories in C SHOULD match layer's class names.
            test.verifyEqual(categories(C),...
                classes);
            
            % Grayscale net SHOULD work with RGB image
            I_stack(:,:,:,1) = I1;
            I_stack(:,:,:,2) = I2;
            I_stack(:,:,:,3) = I3;
            [~,~,~] = semanticseg(I_stack, net,...
                'ExecutionEnvironment', getExeEnv(test));
            
        end
        
        function canSegment3DImages(test,multiImageSizes,isdlnetwork)
            % When px cls layer is not last, semanticseg SHOULD still
            % work. Steps take by test:
            %
            % 1) setup training data for triangle seg.
            % 2) create network where px cls layer is second layer
            %    added.
            % 3) train and call semanticseg.

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);
            
            % Load training images and pixel labels.
            dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
            imageDir = fullfile(dataSetDir, 'trainingImages');
            labelDir = fullfile(dataSetDir, 'trainingLabels');
            
            % Create an imageDatastore holding the training images.
            imds = imageDatastore(imageDir);
            imds.ReadFcn = @(x)iMakeVolume(x,32,1);
            
            % Define the class names and their associated label IDs.
            classNames = ["triangle", "background"];
            labelIDs   = [255 0];
            
            % Create a pixelLabelDatastore holding the ground truth pixel labels for
            % the training images.
            pxds = pixelLabelDatastore(labelDir, classNames, labelIDs);
            pxds.ReadFcn = @(x)categorical(iMakeVolume(x,32,1),labelIDs,classNames);
            
            % Create network for semantic segmentation. Make pixel cls
            % layer the second layer.
            layers = [
                image3dInputLayer([32 32 32 1],'Name','input')
                convolution3dLayer(3, 16, 'Padding', 1, 'Name','conv1')
                reluLayer('Name','relu1')
                maxPooling3dLayer(2, 'Stride', 2,'Name','mpool')
                convolution3dLayer(3, 16, 'Padding', 1,'Name','conv2')
                reluLayer('Name', 'relu2')
                transposedConv3dLayer(4, 16, 'Stride', 2, 'Cropping', 1,'Name','convt');
                convolution3dLayer(1, 2,'Name','conv3');
                softmaxLayer('Name','sf')
                pixelClassificationLayer('Name', 'labels');
                ];
            
            lgraph = layerGraph(layers);
            
            % Create data source for training a semantic segmentation network.
            datasource = pixelLabelImageDatastore(imds,pxds);
            
            % Setup training options. Note MaxEpochs is set to 5 to reduce example
            % run-time.
            options = trainingOptions('sgdm', 'InitialLearnRate', 1e-3, ...
                'MaxEpochs', 5, 'VerboseFrequency', 10);
            
            % Train network.
            net = trainNetwork(datasource, lgraph, options);
            
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            
            % Call semanticseg. This should not error out.
            I3d = repmat(multiImageSizes.I,[1 1 32]);
            C = semanticseg(I3d, net);
            
            test.verifyEqual(size(C), multiImageSizes.expectedOutSize);
            
            % SHOULD also work when input is imds
            imds = imageDatastore('triangleTest.jpg');
            imds.ReadFcn = @(x)iMakeVolume(x,32,1,multiImageSizes.resizeImg);
            ds = semanticseg(imds, net);
            C = read(ds);
            test.verifyEqual(size(C{1}),multiImageSizes.expectedOutSize);
            
            % Check Classes NV pair
            checkClasses(string(classNames));
            checkClasses(cellstr(classNames));
            checkClasses(categorical(classNames, classNames));
            checkClasses('auto');
            checkClasses("auto");

            function checkClasses(classesInput)
                C = semanticseg(I3d, net, 'Classes', classesInput);
                [~] = semanticseg(I3d,net,"Class", classesInput);
                [~] = semanticseg(I3d,net,'Clas', classesInput);
                outSize = multiImageSizes.expectedOutSize;
                test.verifyEqual(size(C),outSize);
                actCats = categories(C);
                if iIsAuto(classesInput) && isdlnetwork
                    numClasses = numel(classNames(:));
                    classes = 1:numClasses;
                    classes = "C" + classes;
                    expCats = cellstr(classes(:));
                else
                    expCats = cellstr(classNames(:));
                end
                test.verifyEqual(actCats,expCats);
            end
        end
        
        function canSegmentALogicalImage(test, inputBasedOnDims, isdlnetwork)
            % SHOULD return categorical, scores, allScores
            I = imread('triangleImages/image_1.jpg');
            Ilogical = logical(I);
            Ilogical = repmat(Ilogical, [1 1 inputBasedOnDims.depth]);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end
            [C, scores, allScores] = semanticseg(Ilogical, trainedNet, 'ExecutionEnvironment', getExeEnv(test));
            
            test.verifyEqual(size(C), size(scores));
            
            [predictInput, classes] = iGetPredictInputAndClasses(trainedNet, Ilogical, isdlnetwork);            
            
            % allScores SHOULD equal result of calling predict. And
            % allScores SHOULD sum to 1 along third dim
            predictScores = predict(trainedNet, predictInput);
            if isdlarray(predictScores)
                predictScores = extractdata(predictScores);
            end
            test.verifyTrue(all(ismembertol(allScores, predictScores, single(1e-4)), 'all'))
            test.verifyTrue(all(ismembertol(sum(allScores,inputBasedOnDims.concatInDim-1), ...
                ones(size(scores), 'single'), single(1e-6)), "all"));
            
            % categories in C SHOULD match layer's class names.
            test.verifyEqual(categories(C), classes);
        end
        
        function errorIfImageSmallerThanNetwork(test, isdlnetwork)
            % SHOULD throw error if I is smaller than network image size.
            net = test.TriangleNet;
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            test.verifyError(@()semanticseg(ones(31,32), net, 'ExecutionEnvironment', getExeEnv(test)), ...
                'vision:ObjectDetector:imageSmallerThanNetwork');
            
            net = test.Triangle3DNet;
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            test.verifyError(@()semanticseg(ones(33,32,31), net, 'ExecutionEnvironment', getExeEnv(test)), ...
                'vision:ObjectDetector:imageSmallerThanNetwork');
        end
        
        function pixelClassificationLayerNotLastInLayers(test, isdlnetwork)
            % When px cls layer is not last, semanticseg SHOULD still
            % work. Steps take by test:
            %
            % 1) setup training data for triangle seg.
            % 2) create network where px cls layer is second layer
            %    added.
            % 3) train and call semanticseg.

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);
            
            % Load training images and pixel labels.
            dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
            imageDir = fullfile(dataSetDir, 'trainingImages');
            labelDir = fullfile(dataSetDir, 'trainingLabels');
            
            % Create an imageDatastore holding the training images.
            imds = imageDatastore(imageDir);
            
            % Define the class names and their associated label IDs.
            classNames = ["triangle", "background"];
            labelIDs   = [255 0];
            
            % Create a pixelLabelDatastore holding the ground truth pixel labels for
            % the training images.
            pxds = pixelLabelDatastore(labelDir, classNames, labelIDs);
            
            % Create network for semantic segmentation. Make pixel cls
            % layer the second layer.
            layersToAdd = [
                imageInputLayer([32 32 1],'Name','input')
                pixelClassificationLayer('Name', 'labels');
                convolution2dLayer(3, 64, 'Padding', 1, 'Name','conv1')
                reluLayer('Name','relu1')
                maxPooling2dLayer(2, 'Stride', 2,'Name','mpool')
                convolution2dLayer(3, 64, 'Padding', 1,'Name','conv2')
                reluLayer('Name', 'relu2')
                transposedConv2dLayer(4, 64, 'Stride', 2, 'Cropping', 1,'Name','convt');
                convolution2dLayer(1, 2,'Name','conv3');
                softmaxLayer('Name','sf')
                ];
            
            lgraph = layerGraph();
            
            % add layers
            for i = 1:numel(layersToAdd)
                lgraph = addLayers(lgraph, layersToAdd(i));
            end
            
            % connect layers
            lgraph = connectLayers(lgraph,'input','conv1');
            lgraph = connectLayers(lgraph,'conv1','relu1');
            lgraph = connectLayers(lgraph,'relu1','mpool');
            lgraph = connectLayers(lgraph,'mpool','conv2');
            lgraph = connectLayers(lgraph,'conv2','relu2');
            lgraph = connectLayers(lgraph,'relu2','convt');
            lgraph = connectLayers(lgraph,'convt','conv3');
            lgraph = connectLayers(lgraph,'conv3','sf');
            lgraph = connectLayers(lgraph,'sf','labels');
            
            % Create data source for training a semantic segmentation network.
            datasource = pixelLabelImageDatastore(imds,pxds);
            
            % Setup training options. Note MaxEpochs is set to 5 to reduce example
            % run-time.
            options = trainingOptions('sgdm', 'InitialLearnRate', 1e-3, ...
                'MaxEpochs', 5, 'VerboseFrequency', 10);
            
            % Train network.
            net = trainNetwork(datasource, lgraph, options);
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            
            % Call semanticseg. This should not error out.
            I = imread('triangleTest.jpg');
            C = semanticseg(I, net);
            
            test.verifyEqual(size(C),[256 256]);
            
            % SHOULD also work when input is imds
            imds = imageDatastore('triangleTest.jpg');
            ds = semanticseg(imds, net);
            C = read(ds);
            test.verifyEqual(size(C{1}),[256 256]);
            
        end
        
        function canSegmentDicePixelClassificationLayer(test, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);
            
            % Load the training data.
            
            dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
            imageDir = fullfile(dataSetDir,'trainingImages');
            labelDir = fullfile(dataSetDir,'trainingLabels');
            
            % Create an image datastore for the images.          
            imds = imageDatastore(imageDir);
            
            % Create a |pixelLabelDatastore| for the ground truth pixel labels.           
            classNames = ["triangle","background"];
            labelIDs   = [255 0];
            pxds = pixelLabelDatastore(labelDir,classNames,labelIDs);
            
            % Create a semantic segmentation network. This network uses a simple semantic
            % segmentation network based on a downsampling and upsampling design.           
            numFilters = 64;
            filterSize = 3;
            numClasses = 2;
            layers = [
                imageInputLayer([32 32 1])
                convolution2dLayer(filterSize,numFilters,'Padding',1)
                batchNormalizationLayer()
                reluLayer()
                maxPooling2dLayer(2,'Stride',2)
                convolution2dLayer(filterSize,numFilters,'Padding',1)
                batchNormalizationLayer()
                reluLayer()
                transposedConv2dLayer(4,numFilters,'Stride',2,'Cropping',1);
                convolution2dLayer(1,numClasses);
                softmaxLayer()
                dicePixelClassificationLayer()
                ];
            
            % Create a pixel label image datastore that contains training data.          
            trainingData = pixelLabelImageDatastore(imds,pxds);
            
            % Setup training options         
            opts = trainingOptions('sgdm', 'InitialLearnRate',1e-3, ...
                'MaxEpochs',50, 'MiniBatchSize',64);
            
            % Train the network.    
            net = trainNetwork(trainingData,layers,opts);
            if isdlnetwork
                net = iGetDlnetwork(net);
            end
            
            % Read  a test image.            
            testImage = imread('triangleTest.jpg');

            % Segment the test image and display the results.         
            C = semanticseg(testImage,net);
            test.verifyEqual(size(C),[256 256]);
            
            % SHOULD also work when input is imds
            imds = imageDatastore('triangleTest.jpg');
            ds = semanticseg(imds,net);
            C = read(ds);
            test.verifyEqual(size(C{1}),[256 256]);
        end
        
        function customClassificationLayer(test)
            % semanticseg should work when a user provides a custom
            % classification layer.
            
            I = imread('triangleTest.jpg');
            expected = semanticseg(I,test.TriangleNet);
            
            layers = test.TriangleNet.Layers;
            
            customLayer = hCustomClassificationLayer();
            customLayer.Classes = layers(end).Classes;
            
            layers(end) = customLayer;
            netWithCustomLayer = assembleNetwork(layers);
            
            actual = semanticseg(I,netWithCustomLayer);
            
            test.verifyTrue(isequal(actual,expected))
        end
    end
    
    %% Test Name-value pairs
    methods(Test)
        function testMinibatchSize(test, inputBasedOnDims, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            imds.ReadFcn = @(x)iMakeVolume(x,inputBasedOnDims.depth,1);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end

            % cd to directory. writes to pwd.
            pxdsExp = semanticseg(imds, trainedNet, 'MiniBatchSize',2, 'ExecutionEnvironment', getExeEnv(test));
            pxdsAct = semanticseg(imds, trainedNet, 'minibatch',2, 'ExecutionEnvironment', getExeEnv(test));
            
            [~, fnamesAct] = fileparts(pxdsAct.Files);
            [~, fnamesExp] = fileparts(pxdsExp.Files);

            test.verifyEqual(fnamesAct,fnamesExp);
            test.verifyEqual(pxdsAct.ClassNames,pxdsExp.ClassNames);
            test.verifyEqual(pxdsAct.ReadSize,pxdsExp.ReadSize);
        end
        
        function testMinibatchSizeInMemory(test, inputBasedOnDims, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            imds.ReadFcn = @(x)iMakeVolume(x,inputBasedOnDims.depth,1);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end

            % cd to directory. writes to pwd.
            inMemoryInput = readall(imds);
            inMemoryInput = cat(inputBasedOnDims.concatInDim, inMemoryInput{:});
            pxdsExp = semanticseg(imds, trainedNet, 'MiniBatchSize',2, 'ExecutionEnvironment', getExeEnv(test));
            pxAct = semanticseg(inMemoryInput, trainedNet, 'minibatch',2, 'ExecutionEnvironment', getExeEnv(test));
            
            pxExp = readall(pxdsExp);
            dimToCat = inputBasedOnDims.ndims + 1;
            pxExp = cat(dimToCat,pxExp{:});
            test.verifyTrue(isequal(pxAct,pxExp));
            test.verifyEqual(categories(pxAct),pxdsExp.ClassNames);
        end
        
        function testExecutionEnvironment(test, inputBasedOnDims, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            imds.ReadFcn = @(x)iMakeVolume(x,inputBasedOnDims.depth,1);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end
            
            % cd to directory. writes to pwd.
            pxdsExp = semanticseg(imds, trainedNet,'ExecutionEnvironment', getExeEnv(test));
            pxdsAct = semanticseg(imds, trainedNet,'executionEnv', getExeEnv(test));

            [~, fnamesAct] = fileparts(pxdsAct.Files);
            [~, fnamesExp] = fileparts(pxdsExp.Files);

            test.verifyEqual(fnamesAct,fnamesExp);
            
            test.verifyEqual(pxdsAct.ClassNames,pxdsExp.ClassNames);
            test.verifyEqual(pxdsAct.ReadSize,pxdsExp.ReadSize);
        end
        
        function testWriteLocation(test, inputBasedOnDims, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            imds.ReadFcn = @(x)iMakeVolume(x,inputBasedOnDims.depth,1);
            
            trainedNet = eval(inputBasedOnDims.loadNet);
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end
            
            % cd to directory. writes to pwd.
            pxdsExp = semanticseg(imds, trainedNet, 'WriteLocation',pwd, 'ExecutionEnvironment', getExeEnv(test));
            pxdsAct = semanticseg(imds, trainedNet, 'writeLoc',pwd, 'ExecutionEnvironment', getExeEnv(test));

            [~, fnamesAct] = fileparts(pxdsAct.Files);
            [~, fnamesExp] = fileparts(pxdsExp.Files);

            test.verifyEqual(fnamesAct,fnamesExp);
            
            test.verifyEqual(pxdsAct.ClassNames,pxdsExp.ClassNames);
            test.verifyEqual(pxdsAct.ReadSize,pxdsExp.ReadSize);
        end
        
        function testNamePrefix(test)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            
            % cd to directory. writes to pwd.
            pxdsExp = semanticseg(imds, test.TriangleNet, 'NamePrefix','new_files',...
                'ExecutionEnvironment', getExeEnv(test));
            pxdsAct = semanticseg(imds, test.TriangleNet, 'nameprefix','new_files',...
                'ExecutionEnvironment', getExeEnv(test));

            [~, fnamesAct] = fileparts(pxdsAct.Files);
            [~, fnamesExp] = fileparts(pxdsExp.Files);

            test.verifyEqual(fnamesAct,fnamesExp);
            
            test.verifyEqual(pxdsAct.ClassNames,pxdsExp.ClassNames);
            test.verifyEqual(pxdsAct.ReadSize,pxdsExp.ReadSize);
        end
        
        function testVerbose(test, isdlnetwork)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);

            imagePath = fullfile(fileparts(mfilename("fullpath")), "SemanticSegTests", "triangleImages");

            imds = imageDatastore(imagePath);
            trainedNet = test.TriangleNet;
            if isdlnetwork
                trainedNet = iGetDlnetwork(trainedNet);
            end
            
            % cd to directory. writes to pwd.            
            diary(fullfile(pwd,'tempDiary1.txt'));
            [~] = semanticseg(imds, trainedNet, 'Verbose',1, 'ExecutionEnvironment', getExeEnv(test));
            diary off
            
            diary(fullfile(pwd,'tempDiary2.txt'));
            [~] = semanticseg(imds, trainedNet, 'verbo',true, 'ExecutionEnvironment', getExeEnv(test));
            diary off
            
            diaryData1 = fileread(fullfile(pwd,'tempDiary1.txt'));
            diaryData2 = fileread(fullfile(pwd,'tempDiary2.txt'));
            
            test.verifyEqual(diaryData2,diaryData1);
        end

    end %methods
end %classdef

%% Local Functions
function settingsBasedOnNumDims = iGetParamsBasedOnNDims()
input2d = struct( ...
    'is3D', false, ...
    'ndims', 2, ...
    'depth', 1, ...
    'concatInDim', 4,...
    'dsExpectedExt', '.png', ...
    'loadNet', 'test.TriangleNet');

input3d = struct( ...
    'is3D', true, ...
    'ndims', 3, ...
    'depth', 32, ...
    'concatInDim', 5,...
    'dsExpectedExt', '.mat', ...
    'loadNet', 'test.Triangle3DNet');


settingsBasedOnNumDims = struct( ...
    'input2d', input2d, ...
    'input3d', input3d);
end

function out = iMakeVolume(x,depthSize,channels,varargin)
if isnumeric(x)
    I = x;
else
    I = imread(x);
    if ~isempty(varargin) && varargin{1}
            I = imresize(I,[32,32]);
    end
end
out = zeros(size(I,1),size(I,2),depthSize,channels);
for idx = 1:channels
    out(:,:,:,idx) = repmat(I(:,:,1),[1 1 depthSize]);
end

end

function layers = iCreate3DSemanticSegLayers(imageSize, numClasses, classNames)
layers = [
    image3dInputLayer(imageSize,'Name','input')
    convolution3dLayer(3, 2, 'Padding', 1, 'Name','conv1')
    reluLayer('Name','relu1')
    maxPooling3dLayer(2, 'Stride', 2,'Name','mpool')
    reluLayer('Name', 'relu2')
    transposedConv3dLayer(4, 4, 'Stride', 2, 'Cropping', 1,'Name','convt');
    convolution3dLayer(1, numClasses,'Name','conv3');
    softmaxLayer('Name','sf')
    pixelClassificationLayer('Name', 'labels','Classes',classNames);
    ];

end

function options = iGetSegTrainingOptions(~)
options = trainingOptions('sgdm', ...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.0005, ...
    'MaxEpochs',1, ...
    'MiniBatchSize',1, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2);
end

function multiImageSizes= iGetInput()
I =  imread('triangleTest.jpg');
originalImage = struct(...
    'I',I,...
    'resizeImg',0,...
    'expectedOutSize',[256 256 32]);

% Image is resized to network input size to make sure predict is called.
I =  imread('triangleTest.jpg');
resizedI = imresize(I,[32,32]);
resizedImage = struct(...
    'I',resizedI,...
    'resizeImg',1,...
    'expectedOutSize',[32 32 32]);

multiImageSizes = struct( ...
    'originalImage', originalImage,...
    'resizedImage', resizedImage);
end

function dlnet = iGetDlnetwork(trainedNet)
switch class(trainedNet)
    case 'DAGNetwork'
        lgraph = layerGraph(trainedNet);
    case 'SeriesNetwork'
        lgraph = layerGraph(trainedNet.Layers);
    otherwise
        error('Valid options: DAGNetwork, SeriesNetwork.')
end
lgraph = removeLayers(lgraph,trainedNet.OutputNames);
dlnet = dlnetwork(lgraph);
end

function [numClasses,dataFormat] = iFindFinalLayerSize(dlnet)
[sizes, formats] = deep.internal.sdk.forwardDataAttributes(dlnet);
% sizes will contain channel and batch dimension at the end
% eg. sizes = {[32,32,2,1]}, formats = {'SSCB'}
numClasses = sizes{1}(end-1);
dataFormat = formats{1};
end

function tf = iIsAuto(val)
tf = isequal(string(val), "auto");
end

function [predictInput, classes] = iGetPredictInputAndClasses(trainedNet, I, isdlnetwork)
if isdlnetwork
    [numClasses,format] = iFindFinalLayerSize(trainedNet);
    predictInput = I;
    if isinteger(predictInput)
        % Cast data to single, if the data is 'int16','uint16', or
        % 'uint8'.
        predictInput = single(predictInput);
    end
    predictInput = dlarray(predictInput, format);
    
    classes = 1:numClasses;
    classes = "C" + classes;
    classes = cellstr(classes(:));
else
    predictInput = I;
    classes = trainedNet.Layers(end).ClassNames;
end

end
