classdef DicePixelClassificationLayerTests < matlab.unittest.TestCase
    % DICEPIXELCLASSIFICATIONLAYERTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties(TestParameter)
        KnownOptionsAndProperties = iGetKnownOptionsAndProperties()
        ValidClasses = iGetValidClasses()
    end
    
    %% Test Methods
    methods(Test)
        function creatingLayerAssignsPropertiesCorrectly(test, ...
                KnownOptionsAndProperties)
            optionalArgs = KnownOptionsAndProperties.OptionalArgs;
            layerProperties = KnownOptionsAndProperties.LayerProperties;
            
            % create layer from user arguments
            layer = dicePixelClassificationLayer(optionalArgs{:});
            
            % check that all properties have changed according to the
            % defined input arguments
            for k=1:2:numel(layerProperties)
                test.verifyEqual( layer.(layerProperties{k}), layerProperties{k+1}, ...
                    "Check that all properties have changed according to the defined input arguments")
            end
        end
        
        function settingClassesAssignsPropertiesCorrectly(test, ...
                ValidClasses)
            layer = dicePixelClassificationLayer();
            layer.Classes = ValidClasses.Classes;
            
            expectedClasses = ValidClasses.ExpectedClasses;
            expectedOutputSize = 'auto';
            
            test.verifyEqual(layer.Classes, expectedClasses, ...
                "Wrong Classes");
            test.verifyEqual(layer.OutputSize, expectedOutputSize, ...
                "Wrong OutputSize");
        end
        
        function settingClassesAssignsClassNames(test)
            % auto
            layer = dicePixelClassificationLayer();
            expectedClassNames = cell(0,1);
            test.verifyEqual(isempty(layer.ClassNames), isempty(expectedClassNames), ...
                "Verify default class names are empty");
            
            % values
            layer.Classes = ["b" "a" "c"];
            expectedClassNames = {'b';'a';'c'};
            test.verifyEqual(layer.ClassNames, expectedClassNames, 'Verify correct layer class names');
        end %function
   
    end %methods
end %classdef

%% Local Functions
%--------------------------------------------------------------------------
function parameter = iGetKnownOptionsAndProperties()
parameter = struct;

% default
optionalArgs = {};
layerProperties = {'Name', '', 'Classes', 'auto','OutputSize', 'auto'};
parameter.Default = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name
optionalArgs = {'Name', 'foo'};
layerProperties = {'Name', 'foo', 'Classes', 'auto', 'OutputSize', 'auto'};
parameter.ClassNamesAuto = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% name, classes string vector
optionalArgs = {'Name', 'foo', 'Classes', ["a" "b"]};
layerProperties = {'Name', 'foo', 'Classes', categorical({'a';'b'}), ...
                   'OutputSize', 'auto'};
parameter.ClassNamesCellstr = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes auto
optionalArgs = {'Name', 'foo', 'Classes','auto'};
layerProperties = {'Name', 'foo', 'Classes', 'auto', ...
                   'OutputSize', 'auto'};
parameter.ClassesAuto = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes cellstr
optionalArgs = {'Name', 'foo', 'Classes',{'b','a'}};
layerProperties = {'Name', 'foo', 'Classes', ...
    categorical({'b';'a'},{'b';'a'}), 'OutputSize', 'auto'};
parameter.ClassesCellstrWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});

% Classes categorical
optionalArgs = {'Name', 'foo', 'Classes', categorical(["a" "b"],'Ordinal',true)};
layerProperties = {'Name', 'foo', 'Classes', ...
    categorical(["a" "b"],'Ordinal',true)', 'OutputSize', 'auto'};
parameter.ClassesCatWeightsNone = struct('OptionalArgs', {optionalArgs}, ...
    'LayerProperties', {layerProperties});
end

%--------------------------------------------------------------------------
function s = iGetValidClasses()
autoClasses = struct('Classes', 'auto', 'ExpectedClasses', 'auto');

cellstrClasses = struct('Classes', {{'b','a'}}, ...
    'ExpectedClasses', categorical({'b','a'},{'b','a'})');

stringClasses = struct('Classes', string(["b" "a"]), ...
    'ExpectedClasses', categorical({'b','a'},{'b','a'})');

categoricalClasses = struct('Classes', ...
    categorical({'a','b'},'Ordinal',true), 'ExpectedClasses',...
    categorical({'a','b'},'Ordinal',true)');

s = struct(...
    'AutoClasses', autoClasses,...
    'CellstrClasses', cellstrClasses, ...
    'StringClasses', stringClasses, ...
    'CategoricalClasses', categoricalClasses);
end
