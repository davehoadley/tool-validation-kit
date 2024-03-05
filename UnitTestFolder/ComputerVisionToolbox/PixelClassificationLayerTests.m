classdef PixelClassificationLayerTests < matlab.unittest.TestCase
    % PIXELCLASSIFICATIONLAYERTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    properties(TestParameter)
        KnownOptionsAndProperties = iGetKnownOptionsAndProperties()
        ValidClassesAndWeights = iGetValidClassesAndWeights()
    end
    
    methods(Test)
        function creatingLayerAssignsPropertiesCorrectly(test, ...
                KnownOptionsAndProperties)
            optionalArgs = KnownOptionsAndProperties.OptionalArgs;
            layerProperties = KnownOptionsAndProperties.LayerProperties;
            
            % create layer from user arguments
            layer = pixelClassificationLayer(optionalArgs{:});
            
            % check that all properties have changed according to the
            % defined input arguments
            for k=1:2:numel(layerProperties)
                test.verifyEqual( layer.(layerProperties{k}), layerProperties{k+1} )
            end
        end
        
        function settingClassesAndWeightsAssignsPropertiesCorrectly(test, ...
                ValidClassesAndWeights)
            layer = pixelClassificationLayer();            
            layer.Classes = ValidClassesAndWeights.Classes;
            layer.ClassWeights = ValidClassesAndWeights.Weights;
            
            expectedClasses = ValidClassesAndWeights.ExpectedClasses;
            expectedWeights = ValidClassesAndWeights.ExpectedWeights;
            expectedOutputSize = 'auto';
            
            test.verifyEqual(layer.Classes, expectedClasses, ...
                "Wrong Classes");
            
            test.verifyEqual(layer.ClassWeights, expectedWeights, ...
                "Wrong ClassWeights");
            
            test.verifyEqual(layer.OutputSize, expectedOutputSize, ...
                "Wrong OutputSize");
        end

        function settingClassesAssignsClassNames(test)
            % auto
            layer = pixelClassificationLayer();   
            expectedClassNames = cell(0,1);            
            test.verifyEqual(isempty(layer.ClassNames), isempty(expectedClassNames), ...
                "Verify default class names are empty");
                        
            % values
            layer.Classes = ["b" "a" "c"];
            expectedClassNames = {'b';'a';'c'};            
            test.verifyEqual(layer.ClassNames, expectedClassNames);            
        end
       
   
    end %methods
end %classdef

%% Local Functions
%--------------------------------------------------------------------------
function parameter = iGetKnownOptionsAndProperties()
parameter = struct;

% default
optionalArgs = {};
layerProperties = {'Name', '', 'Classes', 'auto', 'ClassWeights', 'none',...
    'OutputSize', 'auto'};
parameter.Default = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name, class names='auto'
optionalArgs = {'Name', 'foo', 'ClassNames', 'auto'};
layerProperties = {'Name', 'foo', 'Classes', 'auto', ...
    'ClassWeights', 'none', 'OutputSize', 'auto'};
parameter.ClassNamesAuto = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name, single class name
optionalArgs = {'Name', 'foo', 'ClassNames', "a"};
layerProperties = {'Name', 'foo', 'Classes', categorical({'a'}), ...
    'ClassWeights', 'none', 'OutputSize', 'auto'};
parameter.ClassNamesSingle = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name, class names
optionalArgs = {'Name', 'foo', 'ClassNames', {'a','b'}};
layerProperties = {'Name', 'foo', 'Classes', categorical({'a';'b'}), ...
    'ClassWeights', 'none', ...
    'OutputSize', 'auto'};
parameter.ClassNamesCellstr = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name, class weights = 'none'
optionalArgs = {'Name', 'foo', 'ClassNames', {'a','b'}, ...
    'ClassWeights', 'none'};
layerProperties = {'Name', 'foo', 'Classes', categorical({'a';'b'}), ...
    'ClassWeights', 'none', ...
    'OutputSize', 'auto'};
parameter.ClassWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% no class names,  class weights = 'none'
optionalArgs = {'Name', 'foo', 'ClassWeights', 'none'};
layerProperties = {'Name', 'foo', 'Classes', 'auto', ...
    'ClassWeights', 'none', 'OutputSize', 'auto'};
parameter.NoClassNamesAndWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% class names, class weights
optionalArgs = {'Name', 'foo', 'ClassNames',["a" "b"], 'ClassWeights', [1 1]};
layerProperties = {'Name', 'foo',  'Classes', categorical({'a';'b'}), ...
    'ClassWeights', [1;1], 'OutputSize', 'auto'};
parameter.TwoClassNamesWeightsOnes = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes auto
optionalArgs = {'Name', 'foo', 'Classes','auto'};
layerProperties = {'Name', 'foo', 'Classes', 'auto', ...
    'ClassWeights', 'none', 'OutputSize', 'auto'};
parameter.ClassesAuto = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes cellstr, class weights none
optionalArgs = {'Name', 'foo', 'Classes',{'b','a'}};
layerProperties = {'Name', 'foo', 'Classes', ...
    categorical({'b';'a'},{'b';'a'}), 'ClassWeights', 'none', ...
    'OutputSize', 'auto'};
parameter.ClassesCellstrWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes string, class weights ones
optionalArgs = {'Name', 'foo', 'Classes',["b" "a" "c"], 'ClassWeights', [1 1 1]};
layerProperties = {'Name', 'foo', 'Classes', ...
    categorical({'b';'a';'c'},{'b';'a';'c'}), 'ClassWeights', [1;1;1], ...
    'OutputSize', 'auto'};
parameter.ClassesStringWeightsOnes = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes categorical, class weights none
optionalArgs = {'Name', 'foo', 'Classes', categorical(["a" "b"],'Ordinal',true)};
layerProperties = {'Name', 'foo', 'Classes', ...
    categorical(["a" "b"],'Ordinal',true)', 'ClassWeights', 'none', ...
    'OutputSize', 'auto'};
parameter.ClassesCatWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});
end

%--------------------------------------------------------------------------
function s = iGetValidClassesAndWeights()
autoClassesNoneWeights = struct('Classes', 'auto', 'Weights', 'none', ...
    'ExpectedClasses', 'auto', 'ExpectedWeights', 'none');

cellstrClassesNoneWeights = struct('Classes', {{'b','a'}}, ...
    'Weights', 'none', 'ExpectedClasses', categorical({'b','a'},{'b','a'})',...
    'ExpectedWeights', 'none');

stringClassesNoneWeights = struct('Classes', string(["b" "a"]), ...
    'Weights', 'none', 'ExpectedClasses', categorical({'b','a'},{'b','a'})',...
    'ExpectedWeights', 'none');

categoricalClassesNoneWeights = struct('Classes', ...
    categorical({'a','b'},'Ordinal',true), 'Weights', 'none', 'ExpectedClasses',...
    categorical({'a','b'},'Ordinal',true)', 'ExpectedWeights', 'none');

cellstrClasseTwoWeights = struct('Classes', {{'b','a'}}, ...
    'Weights', [.2 .8], 'ExpectedClasses', categorical({'b','a'},{'b','a'})',...
    'ExpectedWeights', [.2;.8]);

s = struct(...
    'AutoClassesNoneWeights', autoClassesNoneWeights,...
    'CellstrClassesNoneWeights', cellstrClassesNoneWeights, ...
    'StringClassesNoneWeights', stringClassesNoneWeights, ...
    'CategoricalClassesNoneWeights', categoricalClassesNoneWeights, ...
    'CellstrClasseTwoWeights', cellstrClasseTwoWeights);
end
