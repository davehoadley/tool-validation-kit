classdef TrainingOptionsTests < matlab.unittest.TestCase
    % TRAININGOPTIONSTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties(TestParameter)
        SolverName = iGetSolverNames();
        LearnRateScheduleSettings = iLearnRateScheduleSettings();
    end

    %% Test Methods
    methods(Test)
        function publicPropertiesShouldBeAccessible(test,SolverName)
            % The publicly accessible properties for training options
            % SHOULD be accessible and NOT throw any errors or warnings.

            opts = trainingOptions(SolverName);

            propertyList = iGetPropertyListTrainingOptions(opts);

            propListExp = iGetPropListExpected(SolverName);

            propListAct = {};
            for i = 1:numel(propertyList)
                if strcmp(propertyList(i).GetAccess, 'public')
                    propListAct{i} = opts.(propertyList(i).Name); %#ok<*AGROW>
                end
            end
            propListAct(cellfun(@isempty, propListAct)) = [];

            test.verifyEqual(propListAct, propListExp, ...
                "The publicly accessible properties for training options SHOULD be accessible and NOT throw any errors or warnings")

        end

        function passingInvalidSolverNameThrowsError(test)
            % When you pass an invalid name for the solver, an error SHOULD
            % be thrown.

            invalidSolverName = 'NotARealSolverName';
            errorID = 'nnet_cnn:trainingOptions:InvalidSolverName';

            try
                trainingOptions(invalidSolverName);
            catch ME
                test.verifyEqual(ME.identifier, errorID, "When you pass an invalid name for the solver, an error SHOULD be thrown")
            end
        end

        function creatingOptionsShouldAssignAndProcessProperties(test,SolverName)
            % When we create training options by passing name/value pairs
            % to "trainingOptions", the resulting object SHOULD have
            % properties with the expected values.

            % common inputs and outputs
            inputsAndOutputs = iGetInputsAndOutputsForCommonTrainingOptions();

            % solver specific inputs and outputs
            defaultOutputs = iGetExpectedOutputsForNoInputForSolver(SolverName);
            nonDefaultOutputs = iGetExpectedOutputsForNonDefaultInputsForSolver(SolverName);

            inputsAndOutputs.('DefaultOutputs') = defaultOutputs;
            inputsAndOutputs.('NonDefaultOutputs') = nonDefaultOutputs;

            fieldNames = fieldnames(inputsAndOutputs);
            for i = 1:numel(fieldNames)
                % get list of input parameters
                inputsAndOutputsForTrainingOptions = inputsAndOutputs.(fieldNames{i});

                inputArgs = inputsAndOutputsForTrainingOptions.Input;

                % create training options object from user arguments
                opts = trainingOptions(SolverName,inputArgs{:});

                % check that all properties have changed according to the
                % defined input arguments
                expectedProp = inputsAndOutputsForTrainingOptions.Expected;
                for k=1:2:numel(expectedProp)
                    test.verifyEqual( opts.(expectedProp{k}), expectedProp{k+1}, "Verify " + expectedProp{k} + " has changed according to the defined input arguments" )
                end
            end
        end

        function specifyingLearnRateOptionsShouldSetLearnRateScheduleSettings(test, SolverName, LearnRateScheduleSettings)
            % Creating a training options with settings for scheduled learn rates
            % should create the correct LearnRateScheduleSettings.

            opts = trainingOptions(SolverName, LearnRateScheduleSettings.Input{:});
            expected = LearnRateScheduleSettings.Expected;
            test.verifyEqual(opts.LearnRateScheduleSettings, expected, ...
                "Creating a training options with settings for scheduled learn rates hould create the correct LearnRateScheduleSettings");
        end

        function learnRateScheduleSettingsAreDependent(test, SolverName)
            % Verify that setting top-level learn rate settings will set
            % the dependent LearnRateScheduleSettings struct values on get.
            df = 0.5;
            dp = 2;
            opts = trainingOptions(SolverName, ...
                'LearnRateSchedule', 'piecewise', ...
                'LearnRateDropFactor', df, ...
                'LearnRateDropPeriod', dp);
            test.verifyEqual(opts.LearnRateDropFactor, df, "Verify correct LearnRateDropFactor from trainingOptions");
            test.verifyEqual(opts.LearnRateDropPeriod, dp, "Verify correct LearnRateDropPeriod from trainingOptions");
            df = df+0.1;
            dp = dp+1;
            opts.LearnRateDropFactor = df;
            opts.LearnRateDropPeriod = dp;
            test.verifyEqual(opts.LearnRateDropFactor, df, "Verify correct LearnRateDropFactor from trainingOptions");
            test.verifyEqual(opts.LearnRateDropPeriod, dp, "Verify correct LearnRateDropPeriod from trainingOptions");
            test.verifyEqual(opts.LearnRateScheduleSettings.DropRateFactor, opts.LearnRateDropFactor, "Verify correct DropRateFactor from trainingOptions");
            test.verifyEqual(opts.LearnRateScheduleSettings.DropPeriod, opts.LearnRateDropPeriod, "Verify correct DropPeriod from trainingOptions");
        end

        function canCreateTrainingOptionsWithDifferentInputArguments(test,SolverName)
            % You SHOULD be able to create a set of training options with
            % different values for the input arguments without receiving an
            % error.

            validInputsForTrainingOptions = iGetValidInputsForCommonTrainingOptions();

            validInputsForSolver = iGetValidInputsForSolver(SolverName);

            validInputsForTrainingOptions = iMergeStructs(validInputsForTrainingOptions,validInputsForSolver);

            fieldNames = fieldnames(validInputsForTrainingOptions);
            for i = 1:numel(fieldNames)
                inputArgs = validInputsForTrainingOptions.(fieldNames{i});
                test.verifyWarningFree(@()trainingOptions(SolverName,inputArgs{:}), ...
                    "Create training options with input arg [" + inputArgs{1} + "] without errors");
            end
        end

    end %methods

end %classdef

function propertyList = iGetPropertyListTrainingOptions(options)
TrainingOptionsClassInformation = metaclass(options);
propertyList = TrainingOptionsClassInformation.PropertyList;
end

function baseStruct = iMergeStructs(baseStruct,s)
fieldNames = fieldnames(s);
for i = 1:numel(fieldNames)
    baseStruct.(fieldNames{i}) = s.(fieldNames{i});
end
end

function solverNames = iGetSolverNames()
solverNames = {'sgdm','adam','rmsprop'};
end

function s = iLearnRateScheduleSettings()
s = struct();

inputs = {'LearnRateSchedule','none'};
expectedFieldNames = {'Method'};
inputsToExpected = @(inputs,expectedFieldNames) cell2struct(inputs(2:2:end),expectedFieldNames,2);
expected = inputsToExpected(inputs,expectedFieldNames);
s.InitialLearnRateAndSchedule = iLearnRateScheduleSettingsStruct(inputs,expected);

piecewiseDropFactor = 0.5;
piecewiseDropPeriod = 2;
inputs = {'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',piecewiseDropFactor,...
    'LearnRateDropPeriod',piecewiseDropPeriod};
expectedFieldNames = {'Method','DropRateFactor','DropPeriod'};
expected = inputsToExpected(inputs, expectedFieldNames);
s.PiecewiseSchedule = iLearnRateScheduleSettingsStruct(inputs,expected);
end

function s = iLearnRateScheduleSettingsStruct(inputs,expected)
s.Input = inputs;
s.Expected = expected;
end

function inputsForTrainingOptions = iGetInputsAndOutputsForCommonTrainingOptions()
piecewiseLearnRateSchedule.Input = {
    'LearnRateSchedule','piecewise', ...
    'InitialLearnRate', 0.01, ...
    'LearnRateDropFactor', 0.2, ...
    'LearnRateDropPeriod',20 ...
    };
piecewiseLearnRateSchedule.Expected = {'LearnRateScheduleSettings', ...
    struct( ...
    'Method','piecewise', ...
    'DropRateFactor', 0.2, ...
    'DropPeriod', 20 ...
    )};

% See g1363611
shufflePartialMatchOnce.Input = {'Shuffle','o'};
shufflePartialMatchOnce.Expected = {'Shuffle','once'};

shufflePartialMatchNever.Input = {'Shuffle','n'};
shufflePartialMatchNever.Expected = {'Shuffle','never'};

shufflePartialMatchEveryEpoch.Input = {'Shuffle','e'};
shufflePartialMatchEveryEpoch.Expected = {'Shuffle','every-epoch'};

learnRateSchedulePartialMatchNone.Input = {'LearnRateSchedule','n','InitialLearnRate', 0.01};
learnRateSchedulePartialMatchNone.Expected = {'LearnRateScheduleSettings', ...
    struct('Method','none')};

% See g1363611
learnRateSchedulePartialMatchPiecewise.Input = {'LearnRateSchedule','pi','InitialLearnRate', 0.01};
learnRateSchedulePartialMatchPiecewise.Expected = {'LearnRateScheduleSettings', ...
    struct('Method','piecewise', ...
    'DropRateFactor', 0.1, ...
    'DropPeriod', 10)};

executionEnvPartialMatchAuto.Input = {'ExecutionEnvironment','au'};
executionEnvPartialMatchAuto.Expected = {'ExecutionEnvironment','auto'};

executionEnvPartialMatchGPU.Input = {'ExecutionEnvironment','gp'};
executionEnvPartialMatchGPU.Expected = {'ExecutionEnvironment','gpu'};

executionEnvPartialMatchCPU.Input = {'ExecutionEnvironment','c'};
executionEnvPartialMatchCPU.Expected = {'ExecutionEnvironment','cpu'};

executionEnvPartialMatchMultiGPU.Input = {'ExecutionEnvironment','mul'};
executionEnvPartialMatchMultiGPU.Expected = {'ExecutionEnvironment','multi-gpu'};

executionEnvPartialMatchParallel.Input = {'ExecutionEnvironment','par'};
executionEnvPartialMatchParallel.Expected = {'ExecutionEnvironment','parallel'};

integerVerbose.Input = {'Verbose',1};
integerVerbose.Expected = {'Verbose',true};

integerResetInputNormalization.Input = {'ResetInputNormalization',0};
integerResetInputNormalization.Expected = {'ResetInputNormalization',false};

% Plots
plotsPartialMatchTrainingProgress.Input = {'Plots','train'};
plotsPartialMatchTrainingProgress.Expected = {'Plots','training-progress'};

plotsPartialMatchNone.Input = {'Plots', 'no'};
plotsPartialMatchNone.Expected = {'Plots', 'none'};

plotsStringTrainingProgress.Input = {'Plots', "training-progress"};
plotsStringTrainingProgress.Expected = {'Plots', 'training-progress'};

plotsStringNone.Input = {'Plots', "none"};
plotsStringNone.Expected = {'Plots', 'none'};

trainingPlotter = iTrainingPlotter();
plotsTrainingPlotter.Input = {'Plots', trainingPlotter};
plotsTrainingPlotter.Expected = {'Plots', trainingPlotter};

% SequenceLength partial matches
sequenceLengthPartialMatchLongest.Input = {'SequenceLength', 'l'};
sequenceLengthPartialMatchLongest.Expected = {'SequenceLength', 'longest'};
sequenceLengthPartialMatchShortest.Input = {'SequenceLength', 's'};
sequenceLengthPartialMatchShortest.Expected = {'SequenceLength', 'shortest'};

% SequencePaddingDirection partial matches
sequencePaddingDirectionPartialMatchLeft.Input = {'SequencePaddingDirection', 'l'};
sequencePaddingDirectionPartialMatchLeft.Expected = {'SequencePaddingDirection', 'left'};
sequencePaddingDirectionPartialMatchRight.Input = {'SequencePaddingDirection', 'r'};
sequencePaddingDirectionPartialMatchRight.Expected = {'SequencePaddingDirection', 'right'};

% SequencePaddingValue
sequencePaddingValueIntToCanonicalForm.Input = {'SequencePaddingValue', uint8(0)};
sequencePaddingValueIntToCanonicalForm.Expected = {'SequencePaddingValue', 0.0};

% OutputNetwork
outputNetworkPartialMatchLastIter.Input = {'OutputNetwork','l'};
outputNetworkPartialMatchLastIter.Expected = {'OutputNetwork','last-iteration'};
outputNetworkPartialMatchBestVal.Input = {'OutputNetwork','b','ValidationData',iValidationCell()};
outputNetworkPartialMatchBestVal.Expected = {'OutputNetwork','best-validation-loss'};

inputsForTrainingOptions = struct( ...
    'PiecewiseLearnRateSchedule', piecewiseLearnRateSchedule, ...
    'ShufflePartialMatchOnce', shufflePartialMatchOnce, ...
    'ShufflePartialMatchNever', shufflePartialMatchNever, ...
    'ShufflePartialMatchEveryEpoch', shufflePartialMatchEveryEpoch, ...
    'LearnRateSchedulePartialMatchNone', learnRateSchedulePartialMatchNone, ...
    'LearnRateSchedulePartialMatchPiecewise', learnRateSchedulePartialMatchPiecewise, ...
    'ExecutionEnvPartialMatchAuto', executionEnvPartialMatchAuto, ...
    'ExecutionEnvPartialMatchGPU', executionEnvPartialMatchGPU, ...
    'ExecutionEnvPartialMatchCPU', executionEnvPartialMatchCPU, ...
    'ExecutionEnvPartialMatchMultiGPU', executionEnvPartialMatchMultiGPU, ...
    'ExecutionEnvPartialMatchParallel', executionEnvPartialMatchParallel, ...
    'IntegerVerbose', integerVerbose, ...
    'IntegerResetInputNormalization', integerResetInputNormalization, ...
    'PlotsPartialMatchTrainingProgress', plotsPartialMatchTrainingProgress, ...
    'PlotsPartialMatchNone', plotsPartialMatchNone, ...
    'PlotsStringTrainingProgress', plotsStringTrainingProgress, ...
    'PlotsStringNone', plotsStringNone, ...
    'PlotsTrainingPlotter', plotsTrainingPlotter, ...
    'SequenceLengthPartialMatchLongest', sequenceLengthPartialMatchLongest, ...
    'SequenceLengthPartialMatchShortest', sequenceLengthPartialMatchShortest, ...
    'SequencePaddingDirectionPartialMatchLeft',sequencePaddingDirectionPartialMatchLeft, ...
    'SequencePaddingDirectionPartialMatchRight', sequencePaddingDirectionPartialMatchRight, ...
    'SequencePaddingValueIntToCanonicalForm', sequencePaddingValueIntToCanonicalForm, ...
    'OutputNetworkPartialMatchLastIter', outputNetworkPartialMatchLastIter, ...
    'OutputNetworkPartialMatchBestVal', outputNetworkPartialMatchBestVal);
end

function inputsForTrainingOptions = iGetValidInputsForCommonTrainingOptions()
inputsForTrainingOptions = struct( ...
    'LearnRateDropFactorZero', {{'LearnRateDropFactor',0}}, ...
    'LearnRateDropFactorOne', {{'LearnRateDropFactor',1}}, ...
    'ValidationDataIMDS', {{'ValidationData', iValidationIMDS}}, ...
    'ValidationDataTable', {{'ValidationData', iValidationTable}}, ...
    'ValidationDataCell', {{'ValidationData', iValidationCell}}, ...
    'ResetInputNormalization', {{'ResetInputNormalization', false}}, ...
    'InfinitePatience', {{'ValidationPatience', Inf}}, ...
    'CheckpointPathEmpty',{{'CheckpointPath',[]}}, ...
    'WorkerLoadEmpty', {{'WorkerLoad',[]}}, ...
    'WorkerLoadWithZeros', {{'WorkerLoad',[1 0 2]}}, ...
    'OutputFcnEmpty', {{'OutputFcn',[]}}, ...
    'OutputFcnDisp', {{'OutputFcn',@disp}}, ...
    'OutputFcnCellArray', {{'OutputFcn',{@disp,@(x)true}}}, ...
    'PlotsNone', {{'Plots', 'none'}}, ...
    'PlotsTrainingProgress', {{'Plots', 'training-progress'}}, ...
    'SequenceLengthChar', {{'SequenceLength', 'shortest'}}, ...
    'SequenceLengthNumeric', {{'SequenceLength', 13}}, ...
    'SequencePaddingNegative', {{'SequencePaddingValue', -7}}, ...
    'SequencePaddingNaN', {{'SequencePaddingValue', NaN}}, ...
    'SequencePaddingDirectionRight', {{'SequencePaddingDirection', 'right'}} );
end

function trainingPlotter = iTrainingPlotter()
trainingPlotter = FakeTrainingPlotter();
end

function imds = iValidationIMDS()
imds = imageDatastore(fullfile(matlabroot,"toolbox","matlab"), ...
    'IncludeSubfolders', true, 'FileExtensions', '.tif', 'LabelSource', 'foldernames');
end

function tbl = iValidationTable()
imagePaths = iImagePathsColumn(fullfile(matlabroot,"toolbox","matlab"));
vectorResponse = iArbitraryData([2 3]);
tbl = table( imagePaths, vectorResponse );
end

function valCell = iValidationCell()
X = iArbitraryData([3 5]);
Y = iArbitraryData([11 3]);
valCell = {X,Y};
end

function imagePaths = iImagePathsColumn( groupName )
groupPath = fullfile(groupName);
ds = imageDatastore(groupPath,'IncludeSubfolders', true, 'FileExtensions', '.tif');
imagePaths = ds.Files;
end

function data = iArbitraryData(dataSize)
n = prod(dataSize);
data = (1:n)/(n+1);
data = reshape(data, dataSize);
end

function s = iGetValidInputsForSolver(solverName)
switch lower(solverName)
    case 'sgdm'
        s = iGetValidInputsForSolverSGDM();
    case 'adam'
        s = iGetValidInputsForSolverADAM();
    case 'rmsprop'
        s = iGetValidInputsForSolverRMSProp();
end
end

function s = iGetValidInputsForSolverSGDM()
s = struct( ...
    'MomentumZero', {{'Momentum',0}}, ...
    'MomentumOne', {{'Momentum',1}}, ...
    'InitialLearnRate1', {{'InitialLearnRate',0.1}}, ...
    'InitialLearnRate2', {{'InitialLearnRate',1}});
end

function s = iGetValidInputsForSolverADAM()
s = struct( ...
    'GradientDecayFactor1', {{'GradientDecayFactor',0}}, ...
    'GradientDecayFactor2', {{'GradientDecayFactor',0.65}}, ...
    'SquaredGradientDecayFactor1', {{'SquaredGradientDecayFactor',0}}, ...
    'SquaredGradientDecayFactor2', {{'SquaredGradientDecayFactor',0.7}}, ...
    'Epsilon1', {{'Epsilon',1e-3}}, ...
    'Epsilon2', {{'Epsilon',0.1}}, ...
    'InitialLearnRate1', {{'InitialLearnRate',0.1}}, ...
    'InitialLearnRate2', {{'InitialLearnRate',1}});
end

function s = iGetValidInputsForSolverRMSProp()
s = struct( ...
    'SquaredGradientDecayFactor1', {{'SquaredGradientDecayFactor',0}}, ...
    'SquaredGradientDecayFactor2', {{'SquaredGradientDecayFactor',0.7}}, ...
    'Epsilon1', {{'Epsilon',1e-3}}, ...
    'Epsilon2', {{'Epsilon',0.1}}, ...
    'InitialLearnRate1', {{'InitialLearnRate',0.1}}, ...
    'InitialLearnRate2', {{'InitialLearnRate',1}});
end

function s = iGetExpectedOutputsForNoInputForSolver(solverName)
switch lower(solverName)
    case 'sgdm'
        s = iGetExpectedOutputsForNoInputForSolverSGDM();
    case 'adam'
        s = iGetExpectedOutputsForNoInputForSolverADAM();
    case 'rmsprop'
        s = iGetExpectedOutputsForNoInputForSolverRMSProp();
end
end

function nvp = iOptionsDefinitionToDefaultValues(def)
names = fieldnames(def);
def2val = @(def,name) def.(name).DefaultValue;
vals = cellfun(@(name) def2val(def,name), names, 'UniformOutput', false);
nvp = [names,vals]';
nvp = nvp(:);
nvp(end+1:end+2) = {'LearnRateScheduleSettings',struct('Method','none')};
end

function s = iGetExpectedOutputsForNoInputForSolverSGDM()
s.Input = {};
def = nnet.internal.cnn.options.TrainingOptionsDefinitionSGDM();
s.Expected = iOptionsDefinitionToDefaultValues(def);
end

function defaults = iGetExpectedOutputsForNoInputForSolverADAM()
defaults.Input = {};
def = nnet.internal.cnn.options.TrainingOptionsDefinitionADAM();
defaults.Expected = iOptionsDefinitionToDefaultValues(def);
end

function defaults = iGetExpectedOutputsForNoInputForSolverRMSProp()
defaults.Input = {};
def = nnet.internal.cnn.options.TrainingOptionsDefinitionRMSProp();
defaults.Expected = iOptionsDefinitionToDefaultValues(def);
end

function s = iGetExpectedOutputsForNonDefaultInputsForSolver(solverName)
switch lower(solverName)
    case 'sgdm'
        s = iGetExpectedOutputsForNonDefaultInputsForSolverSGDM();
    case 'adam'
        s = iGetExpectedOutputsForNonDefaultInputsForSolverADAM();
    case 'rmsprop'
        s = iGetExpectedOutputsForNonDefaultInputsForSolverRMSProp();
end
end

function s = iGetExpectedOutputsForNonDefaultInputsForSolverSGDM()
nonDefaultArgList = {...
    'Momentum', 0.2, ...
    'InitialLearnRate', 0.25, ...
    'L2Regularization', 0.0002, ...
    'MaxEpochs', 60, ...
    'MiniBatchSize', 256, ...
    'ResetInputNormalization',false, ...
    'Verbose', false, ...
    'VerboseFrequency', 100, ...
    'ValidationData', iValidationCell(), ...
    'ValidationFrequency', 3, ...
    'ValidationPatience', 4, ...
    'Shuffle', 'never', ...
    'ExecutionEnvironment', 'cpu', ...
    'WorkerLoad',[1 0 2], ...
    'OutputFcn',@disp, ...
    'Plots','training-progress', ...
    'SequenceLength', 10, ...
    'SequencePaddingValue', NaN, ...
    'SequencePaddingDirection', 'left', ...
    'OutputNetwork', 'best-validation-loss', ...
    'CheckpointFrequency', 3, ...
    'CheckpointFrequencyUnit', 'iteration'};
s.Input = nonDefaultArgList;
s.Expected = nonDefaultArgList;
end

function s = iGetExpectedOutputsForNonDefaultInputsForSolverADAM()
nonDefaultArgList = {...
    'GradientDecayFactor', 0.5, ...
    'SquaredGradientDecayFactor', 0.8, ...
    'Epsilon', 1, ...
    'InitialLearnRate', 0.25, ...
    'L2Regularization', 0.0002, ...
    'MaxEpochs', 60, ...
    'MiniBatchSize', 256, ...
    'ResetInputNormalization',false, ...
    'Verbose', false, ...
    'VerboseFrequency', 100, ...
    'ValidationData', iValidationCell(), ...
    'ValidationFrequency', 3, ...
    'ValidationPatience', 4, ...
    'Shuffle', 'never', ...
    'ExecutionEnvironment', 'cpu', ...
    'WorkerLoad',[1 0 2], ...
    'OutputFcn',@disp, ...
    'Plots','training-progress', ...
    'SequenceLength', 10, ...
    'SequencePaddingValue', NaN, ...
    'SequencePaddingDirection', 'left', ...
    'OutputNetwork', 'best-validation-loss', ...
    'CheckpointFrequency', 3, ...
    'CheckpointFrequencyUnit', 'iteration'};
s.Input = nonDefaultArgList;
s.Expected = nonDefaultArgList;
end

function s = iGetExpectedOutputsForNonDefaultInputsForSolverRMSProp()
nonDefaultArgList = {...
    'SquaredGradientDecayFactor', 0.85, ...
    'Epsilon', 0.3, ...
    'InitialLearnRate', 0.25, ...
    'L2Regularization', 0.0002, ...
    'MaxEpochs', 60, ...
    'MiniBatchSize', 256, ...
    'ResetInputNormalization',false, ...
    'Verbose', false, ...
    'VerboseFrequency', 100, ...
    'ValidationData', iValidationCell(), ...
    'ValidationFrequency', 3, ...
    'ValidationPatience', 4, ...
    'Shuffle', 'never', ...
    'ExecutionEnvironment', 'cpu', ...
    'WorkerLoad',[1 0 2], ...
    'OutputFcn',@disp, ...
    'Plots','training-progress', ...
    'SequenceLength', 10, ...
    'SequencePaddingValue', NaN, ...
    'SequencePaddingDirection', 'left', ...
    'OutputNetwork', 'best-validation-loss', ...
    'CheckpointFrequency', 3, ...
    'CheckpointFrequencyUnit', 'iteration'};
s.Input = nonDefaultArgList;
s.Expected = nonDefaultArgList;
end

function s = iGetPropListExpected(solverName)

switch lower(solverName)
    case "sgdm"
        s = {
            0.900000000000000
            0.0100000000000000
            30
            'none'
            0.100000000000000
            10
            128
            'once'
            1
            'epoch'
            'longest'
            false
            struct("Method", 'none')
            .0001000000000000
            'l2norm'
            Inf
            true
            50
            50
            Inf
            'auto'
            'none'
            0
            'right'
            "auto"
            "auto"
            true
            'auto'
            'last-iteration'}';
    case "adam"
        s = {
            0.900000000000000
            .9990000000000000
            1.00000000000000e-08
            0.00100000000000000
            30
            'none'
            0.100000000000000
            10
            128
            'once'
            1
            'epoch'
            'longest'
            false
            struct("Method", 'none')
            0.000100000000000000
            'l2norm'
            Inf
            true
            50
            50
            Inf
            'auto'
            'none'
            0
            'right'
            "auto"
            "auto"
            true
            'auto'
            'last-iteration'}';
    case "rmsprop"
        s = {
            0.900000000000000
            1.00000000000000e-08
            0.00100000000000000
            30
            'none'
            0.100000000000000
            10
            128
            'once'
            1
            'epoch'
            'longest'
            false
            struct("Method", 'none')
            0.000100000000000000
            'l2norm'
            Inf
            true
            50
            50
            Inf
            'auto'
            'none'
            0
            'right'
            "auto"
            "auto"
            true
            'auto'
            'last-iteration'}';
end %switch
end %function


