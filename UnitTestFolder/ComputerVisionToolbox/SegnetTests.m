classdef SegnetTests < matlab.unittest.TestCase
    % SEGNETTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties
        imds
        pxds
        pxDatasource
    end
    
    properties(TestParameter)
        variousInputs = iVariousInputs();
    end

    %% Test Class Setup Methods
    methods(TestClassSetup)
        function createpixelLabelImageSource(test)
            % Load training images and pixel labels.
            dataDir = fullfile(toolboxdir('vision'),'visiondata');
            imageDir = fullfile(dataDir, 'building');
            labelDir = fullfile(dataDir, 'buildingPixelLabels');

            % Create an imageDatastore holding the training images.
            test.imds = imageDatastore(imageDir);

            % Define the class names and their associated label IDs.
            classNames = ["buildings", "background"];
            labelIDs   = [255 0];

            % Create a pixelLabelDatastore holding the ground truth pixel labels for
            % the training images.
            test.pxds = pixelLabelDatastore(labelDir, classNames, labelIDs);

            % Create data source for training a semantic segmentation network.
            test.pxDatasource = pixelLabelImageDatastore(test.imds,test.pxds);
        end
        function suppressGPUSupportWarning(test)
            import matlab.unittest.fixtures.SuppressedWarningsFixture;
            test.applyFixture(SuppressedWarningsFixture('parallel:gpu:device:DeviceDeprecated'));
        end
    end
   
    %% Test Methods
    methods(Test)
       function verifylayerTypesAndParamsForVGG16Test(testcase)
            % Verify layers' types, and parameters as in 
            % https://github.com/alexgkendall/SegNet-Tutorial/blob/master/Example_Models/segnet_pascal.prototxt
                        
            % Encoder depth
            D = 5;
            
            % Number of convolution layers in each Encoder and Decoder section
            N = {2,2,3,3,3};
            
            % Number of channels denoting the number of inputs to the conv layer
            NumChannelsEncoder = {{3,64},{64,128},{128,256,256},{256,512,512},{512,512,512}};            
            NumChannelsDecoder = {{512,512,512},{512,512,512},{256,256,256},{128,128},{64,64}};
            
            % Number of filters denoting the number of outputs of the conv layer
            NumFiltersEncoder = {{64,64},{128,128},{256,256,256},{512,512,512},{512,512,512}};            
            NumFiltersDecoder = {{512,512,512},{512,512,256},{256,256,128},{128,64},{64,2}};
            
            imageSize = [360 480 3];
            numClasses = 2;
            lgraph = segnetLayers(imageSize, numClasses, 'vgg16');            
            Layers = lgraph.Layers;
            
            flag = false(1,numel(Layers));
            
            % Verify First layer is input layer
            idx = 1;            
            flag(idx) = isequal(class(Layers(1)),'nnet.cnn.layer.ImageInputLayer');            
            idx = idx + 1;
            
            % Verify the Encoder section layer types, and parameters            
            for i = 1:D
               % Each Encoder section
               for j = 1:N{i}
                   % Each convolution layer
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.Convolution2DLayer')...
                                && isequal(Layers(idx).NumChannels,NumChannelsEncoder{i}{j})...
                                && isequal(Layers(idx).NumFilters,NumFiltersEncoder{i}{j});
                   idx = idx + 1;
                   
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.BatchNormalizationLayer');
                   idx = idx + 1;
                   
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.ReLULayer');
                   idx = idx + 1;
               end
               flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.MaxPooling2DLayer')...
                            && isequal(Layers(idx).PoolSize,[2 2])...
                            && isequal(Layers(idx).Stride,[2 2]);
               idx = idx + 1;               
            end
            
            % Verify the Decoder section layer types, and parameters            
            for i = 1:D
               % Each Decoder section               
               flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.MaxUnpooling2DLayer');
               idx = idx + 1;  
               for j = 1:N{end-i+1}
                   % Each convolution layer
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.Convolution2DLayer')...
                                && isequal(Layers(idx).NumChannels,NumChannelsDecoder{i}{j})...
                                && isequal(Layers(idx).NumFilters,NumFiltersDecoder{i}{j});
                   idx = idx + 1;
                   
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.BatchNormalizationLayer');
                   idx = idx + 1;
                   
                   flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.ReLULayer');
                   idx = idx + 1;
               end             
            end
            
            flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.SoftmaxLayer');
            idx = idx + 1;
            
            flag(idx) = isequal(class(Layers(idx)),'nnet.cnn.layer.PixelClassificationLayer');
            
            % Verify layer types and parameters
            testcase.verifyTrue(all(flag));
        end
        
        function verifyConvLayersDisabledBiasTest(testcase,variousInputs)
            lgraph = variousInputs.lgraph();
            
            allZeroBias = [];
            
            for i = 1:numel(lgraph.Layers)
               if  isequal(class(lgraph.Layers(i)),'nnet.cnn.layer.Convolution2DLayer')
                   numFilters = lgraph.Layers(i).NumFilters;
                   biasExp = zeros(1,1,numFilters);
                   n = 1;
                   if (isequal(lgraph.Layers(i).Bias,biasExp) &&...
                       isequal(lgraph.Layers(i).BiasLearnRateFactor, 0) && ...
                       isequal(lgraph.Layers(i).BiasL2Factor, 0))
                      allZeroBias(n) = true; %#ok<*AGROW> 
                      n = n + 1; %#ok<*NASGU> 
                   else
                      allZeroBias(n) = false;
                      n = n+ 1;
                   end
               end
            end
            
            testcase.verifyTrue(all(allZeroBias));
        end

        function verifySinglePixelClassificationLayerTest(testcase,variousInputs)
            lgraph = variousInputs.lgraph();
            
            numPixelLayers = 0; 
            for i = 1:numel(lgraph.Layers)
               if  isequal(class(lgraph.Layers(i)),'nnet.cnn.layer.PixelClassificationLayer')
                    numPixelLayers = numPixelLayers + 1;
               end
            end
            
            testcase.verifyEqual(numPixelLayers,1);
        end
   
    end %methods
end %classdef

%% Local Functions

function segLgraph = iVariousInputs()

lgraphEncoder.imageSize = [360 480 3];
lgraphEncoder.numClasses = 2;
lgraphEncoder.encoderDepth = 4;
lgraphEncoder.lgraph = @()segnetLayers(lgraphEncoder.imageSize, lgraphEncoder.numClasses, lgraphEncoder.encoderDepth);

lgraphEncoderConvLayers.imageSize = [360 480 3];
lgraphEncoderConvLayers.numClasses = 2;
lgraphEncoderConvLayers.encoderDepth = 4;
lgraphEncoderConvLayers.numConvLayers = 3;
lgraphEncoderConvLayers.lgraph = @()segnetLayers(lgraphEncoderConvLayers.imageSize,...
    lgraphEncoderConvLayers.numClasses, lgraphEncoderConvLayers.encoderDepth,...
    'NumConvolutionLayers',lgraphEncoderConvLayers.numConvLayers);

lgraphEncoderOutputChannels.imageSize = [360 480 3];
lgraphEncoderOutputChannels.numClasses = 2;
lgraphEncoderOutputChannels.encoderDepth = 4;
lgraphEncoderOutputChannels.numOutChannels = 72;
lgraphEncoderOutputChannels.lgraph = @()segnetLayers(lgraphEncoderOutputChannels.imageSize,...
    lgraphEncoderOutputChannels.numClasses, lgraphEncoderOutputChannels.encoderDepth,...
    'NumOutputChannels',lgraphEncoderOutputChannels.numOutChannels);

lgraphEncoderFilterSize.imageSize = [360 480 3];
lgraphEncoderFilterSize.numClasses = 2;
lgraphEncoderFilterSize.encoderDepth = 4;
lgraphEncoderFilterSize.filterSize = 5;
lgraphEncoderFilterSize.lgraph = @()segnetLayers(lgraphEncoderFilterSize.imageSize,...
    lgraphEncoderFilterSize.numClasses, lgraphEncoderFilterSize.encoderDepth,...
    'FilterSize',lgraphEncoderFilterSize.filterSize);

allPVPairs.imageSize = [360 480 3];
allPVPairs.numClasses = 2;
allPVPairs.encoderDepth = 4;
allPVPairs.filterSize = 5;
allPVPairs.numConvLayers = 3;
allPVPairs.numOutChannels = 72;
allPVPairs.lgraph = @()segnetLayers(allPVPairs.imageSize, allPVPairs.numClasses,...
    allPVPairs.encoderDepth,'NumConvolutionLayers',allPVPairs.numConvLayers,...
    'NumOutputChannels',allPVPairs.numOutChannels,'FilterSize',allPVPairs.filterSize);

lgraphVGG16.imageSize = [360 480 3];
lgraphVGG16.numClasses = 2;
lgraphVGG16.lgraph = @()segnetLayers(lgraphVGG16.imageSize, lgraphVGG16.numClasses, 'vgg16');

lgraphVGG19.imageSize = [360 480 3];
lgraphVGG19.numClasses = 2;
lgraphVGG19.lgraph = @()segnetLayers(lgraphVGG19.imageSize, lgraphVGG19.numClasses, 'vgg19');

segLgraph = struct(...
            'withOnlyDepth',lgraphEncoder,...
            'withNumConvLayers',lgraphEncoderConvLayers,...
            'withNumOutputChannels',lgraphEncoderOutputChannels,...
            'withFilterSize',lgraphEncoderFilterSize,...
            'allPVPairs',allPVPairs,...
            'withVGG16',lgraphVGG16,...
            'withVGG19',lgraphVGG19);            
end