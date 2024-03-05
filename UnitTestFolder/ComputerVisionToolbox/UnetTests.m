classdef UnetTests < matlab.unittest.TestCase
    % UNETTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties(TestParameter)
        InputSize = {[160 160], [160 160 3] [160 160 6]};
        FilterSize = {3, [7 7]};
        EncoderDepth = {3, 4};
        NumFirstEncoderFilters = {48, 64, 80};
        ParamsForFilterSizeAndConvPadding = ...
            iGetParamsForFilterSizeAndConvPadding();
    end

    %% Test Methods
    methods(Test)
        function testDefaultValues(test)
            % Testpoint to verify the default values of the layers created.
            input = [16 32 3];
            numClasses = 4;
            unet1 = unetLayers(input, numClasses);
            filterSize = 3;
            encoderDepth = 4;
            numFirstEncoderFilters = 64;
            padding = 'same';
            unet2 = unetLayers(input, numClasses, 'EncoderDepth', ...
                encoderDepth, 'NumFirstEncoderFilters', ...
                numFirstEncoderFilters, 'ConvolutionPadding', padding,...
                'FilterSize', filterSize);
            tf = iVerifyLayerEquality(unet1, unet2, 1e-4);
            test.verifyTrue(tf);
            test.verifyEqual(unet1.Connections, unet2.Connections);

            % Input size should be same as user specified input.
            idxInput2d = arrayfun( @(x)isa(x,...
                'nnet.cnn.layer.ImageInputLayer'),unet1.Layers);
            test.verifyEqual(unet1.Layers(idxInput2d).InputSize, input);

            % filterSize should be same for all convolution layers as per
            % FilterSize NV pair except last convolution layer.
            % All the convolution layers should have 'WeightInitializer'
            % property set to 'he' and 'BiasInitializer' property set to
            % 'zeros'.
            idxConvLayer = find(arrayfun( @(x)isa(x,...
                'nnet.cnn.layer.Convolution2DLayer'),unet1.Layers));
            filterSizes = {};
            weightString = {};
            baisString = {};
            for i=1:length(idxConvLayer)
                filterSizes{i} = unet1.Layers....
                    (idxConvLayer(i)).FilterSize; %#ok<*AGROW> 
                weightString{i} = unet1.Layers....
                    (idxConvLayer(i)).WeightsInitializer;
                baisString{i} = unet1.Layers....
                    (idxConvLayer(i)).BiasInitializer;
            end
            test.verifyEqual(filterSizes(1:length(idxConvLayer)-1), ...
                repmat({[filterSize,filterSize]}, ...
                [1,length(idxConvLayer)-1]));

            test.verifyEqual(weightString, ...
                repmat({'he'}, [1,length(idxConvLayer)]));

            test.verifyEqual(baisString, ...
                repmat({'zeros'}, [1,length(idxConvLayer)]));

            % Number of classes should be equal to number of filters of
            % final 1x1 convolution layer.
            idxLastConv = arrayfun( @(x)isequal(x.Name,...
                'Final-ConvolutionLayer'), unet1.Layers);
            test.verifyEqual(numClasses,unet1.Layers...
                (idxLastConv).NumFilters);

            % First convolution layer number of channels should be equal to
            % NV pair parameter NumFirstEncoderFilters.
            idxFirstConv = arrayfun( @(x)strcmp(x.Name,...
                'Encoder-Stage-1-Conv-1'), unet1.Layers);

            test.verifyEqual(unet1.Layers(idxFirstConv).NumFilters, ...
                numFirstEncoderFilters);

            % Max-pooling layers = EncoderDepth
            idxMaxpool2d = find(arrayfun( @(x)isa(x,...
                'nnet.cnn.layer.MaxPooling2DLayer'),unet1.Layers));
            test.verifyEqual(length(idxMaxpool2d), encoderDepth);

            % Transposed convolution layers = EncoderDepth.
            idxTransposeConv2d = find(arrayfun( @(x)isa(x,...
                'nnet.cnn.layer.TransposedConvolution2DLayer'),...
                unet1.Layers));
            test.verifyEqual(length(idxTransposeConv2d), encoderDepth);

            % Padding for all convolution layers as per ConvolutionPadding
            % NV pair.
            paddingModes = {};
            for i=1:length(idxConvLayer)
                paddingModes{i} = unet1.Layers(idxConvLayer(i)).PaddingMode;
            end
            if strcmp(padding, "valid")
                test.verifyEqual(paddingModes,repmat({'manual'},[1,i]));
            else
                test.verifyEqual(paddingModes,repmat({padding},[1,i]));
            end
        end

        function verifyEncoderAndDecoderSections(test)
            % Testpoint to verify that there are only EncoderDepth number
            % of Encoder and Decoder sections.

            encoderDepth = 4;
            unet = unetLayers([96 96], 2, 'EncoderDepth', encoderDepth);

            % Get the names of the layers.
            layerNames = {unet.Layers(:).Name};

            encDecFlag = false([1 encoderDepth]);

            % There should be encoderDepth levels of Encoder and Decoder
            % sections.
            for i = 1:encoderDepth
                encoderLayers = cellfun(@(x) contains(x, ...
                    ['Encoder-Stage-' num2str(i)]), layerNames);
                decoderLayers = cellfun(@(x) ...
                    contains(x, ['Decoder-Stage-' num2str(i)]), layerNames);

                encDecFlag(i) = any(encoderLayers)*any(decoderLayers);
            end

            % Verify that there are no Encoder and Decoder levels beyond
            % encoderDepth number.
            noEncoderLayers = cellfun(@(x) contains(x, ...
                ['Encoder-Stage-' num2str(encoderDepth+1)]), layerNames);
            noDecoderLayers = cellfun(@(x) contains(x, ...
                ['Decoder-Stage-' num2str(encoderDepth+1)]), layerNames);

            test.verifyTrue(all(encDecFlag) & ~all(noEncoderLayers) ...
                & ~all(noDecoderLayers))
        end

        function verifyNumChannelsInEncoderAndDecoderSections(test)
            % Testpoint to verify same number of channels for last
            % convolution layer of each encoder and decoder section.
            numFirstEncoderFilters = 128;
            unet = unetLayers([96 96], 2, 'NumFirstEncoderFilters', ...
                numFirstEncoderFilters);

            encoderLevel = 1;
            decoderLevel = 1;

            encoderChannel = [];
            decoderChannel = [];

            for i = 1:length(unet.Layers)

                if contains(unet.Layers(i).Name, ['Encoder-Stage-' ...
                        num2str(encoderLevel) '-Conv-2'])
                    encoderChannel = [encoderChannel ...
                        unet.Layers(i).NumChannels];

                    encoderLevel = encoderLevel+1;
                end

                if contains(unet.Layers(i).Name, ['Decoder-Stage-' ...
                        num2str(decoderLevel) '-Conv-2'])
                    decoderChannel = [unet.Layers(i).NumChannels...
                        decoderChannel];

                    decoderLevel = decoderLevel+1;
                end
            end

            test.verifyEqual(encoderChannel, decoderChannel)
        end

        function verifyValidConvolutionPadding(test)
            % Testpoint to verify "valid" Convolution Padding NV pair.
            filterSize = [7 7];
            encoderDepth = 1;
            numFirstEncoderFilters = 32;
            padding = 'valid';
            unet = unetLayers([100 100 3], 3, 'EncoderDepth', ...
                encoderDepth, 'FilterSize', filterSize, ...
                'NumFirstEncoderFilters', numFirstEncoderFilters, ...
                'ConvolutionPadding', padding);
            decoderLevel = 1;
            numCrop2dLayers = 0;
            for i = 1:length(unet.Layers)
                if contains(unet.Layers(i).Name, ...
                        ['Crop2d-' num2str(decoderLevel)])
                    decoderLevel = decoderLevel+1;
                    numCrop2dLayers = numCrop2dLayers + 1;
                end
            end
            test.verifyEqual(numCrop2dLayers, encoderDepth)
        end

        function testDifferentParameters(test, InputSize, EncoderDepth, ...
                NumFirstEncoderFilters, FilterSize)

            flag = true;
            try
                unet = unetLayers(InputSize, 4,...
                    'EncoderDepth', EncoderDepth, ...
                    'NumFirstEncoderFilters', ...
                    NumFirstEncoderFilters, 'FilterSize', FilterSize); %#ok<NASGU> 
            catch
                flag = false;
            end

            test.verifyTrue(flag, "Verify construction of parameter set.");

        end

        function verifyOutputSize(test,ParamsForFilterSizeAndConvPadding)
            % Testpoint to check output argument in "valid" and "same"
            % convolution settings.
            inputSize = [100 100];
            [~, outputSize] = unetLayers(inputSize, 4, ...
                'EncoderDepth', 1, 'ConvolutionPadding', ...
                ParamsForFilterSizeAndConvPadding.Padding, 'FilterSize', ...
                ParamsForFilterSizeAndConvPadding.FilterSize);
            test.verifyEqual(outputSize(1:2),inputSize);
        end

    end
end

%% Local Functions
function [tf, layerName, propName, discrepancy]  = ...
    iVerifyLayerEquality(net1,net2,tolerance)
if nargin == 2
    tolerance = 1e-4;
end

tf = true;
layerName = '';
propName = '';
discrepancy = [];
if numel(net1.Layers)== numel(net2.Layers)
    for  i = 1:numel(net1.Layers)
        props1 = properties(net1.Layers(i));
        props2 = properties(net2.Layers(i));

        layerName = net1.Layers(i).Name;

        if isequal(props1,props2)
            for j = 1:numel(props1)
                val1 = eval(['net1.Layers(', ...
                    num2str(i), ').', props1{j}]);
                val2 = eval(['net2.Layers(', ...
                    num2str(i), ').', props2{j}]);

                propName = props1{j};

                if isequal(propName,'Weights')
                    continue
                elseif isequal(propName,'Bias')
                    absDiff = abs(val1-val2);
                    discrepancy = absDiff;
                    if max(absDiff(:)) > tolerance
                        tf = false;
                        return
                    end
                else
                    if ~isequal(val1,val2)
                        discrepancy = 'unequal';
                        tf = false;
                        return
                    end
                end
            end
        else
            tf = false;
            return
        end
    end
else
    tf = false;
end
end

function variousParams = iGetParamsForFilterSizeAndConvPadding()
sameConv = struct('Padding', 'same', 'FilterSize', 3);
validConv = struct('Padding', 'valid', 'FilterSize', 1);
variousParams = struct('sameConv', sameConv, 'validConv', validConv);
end