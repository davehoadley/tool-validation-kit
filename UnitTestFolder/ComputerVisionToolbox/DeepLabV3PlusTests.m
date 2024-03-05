classdef DeepLabV3PlusTests < matlab.unittest.TestCase
    % DEEPLABV3PLUSTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties(TestParameter)
        SpPkgName = struct(...
            'resnet18', 'resnet18', ...
            'inceptionresnetv2', 'inceptionresnetv2', ...
            'mobilenetv2', 'mobilenetv2', ...
            'resnet50', 'resnet50', ...
            'xception','xception');

        LayerMatch = struct(...
            'resnet18', 'res5b_relu', ...
            'inceptionresnetv2', 'conv_7b_ac', ...
            'mobilenetv2', 'block_16_project_BN', ...
            'resnet50', 'activation_49_relu', ...
            'xception','block14_sepconv2_act');

        ExpAdditionalLayer = struct(...
            'resnet18', 33, ...
            'inceptionresnetv2', 33, ...
            'mobilenetv2', 39', ...
            'resnet50', 33, ...
            'xception', 39);
    end
    
    %% Test Methods
    methods(Test, ParameterCombination = 'sequential')
        
        function checkDeepLabv3PlusLayersTest(test, SpPkgName, LayerMatch, ExpAdditionalLayer)
                        
            % Check the layer is created/replaced properly
            imageSize = [512 512];
            numClasses = 21;
            lgraph = deeplabv3plusLayers(imageSize, numClasses, SpPkgName, "Downsampling", 8);
            
            % Verify default values
            dlayerNames = {lgraph.Layers.Name};
            baseNetwork = eval(SpPkgName);
            
            % Deeplabv3+ should be the same as resnet18 up to
            % the res5b_relu layer
            layer2match = LayerMatch;
            expAdditionalLayer = ExpAdditionalLayer;
            baseNetNames = {baseNetwork.Layers.Name};
            idx = find(strcmp(baseNetNames, layer2match ));
            test.verifyEqual(baseNetNames(1:idx), dlayerNames(1:idx), ...
                "Deeplabv3+ should be the same as resnet18 up to the res5b_relu layer");
                            
            % We always have a fixed amount of layers on top of the backbone network
            test.verifyEqual(numel(dlayerNames) - idx, expAdditionalLayer, ...
                "Verify fixed amount of layers on top of the backbone network");
        end %function
  
    end %methods
end %classdef
