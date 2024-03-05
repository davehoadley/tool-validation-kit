classdef TrainNetworkTests < matlab.unittest.TestCase
    % TRAINNETWORKTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    properties(TestParameter)
        SolverName = iGetSolverNames();
    end
    
    methods(Test)
        function trainingSimplestNetworkGivesTheExpectedAccuracy(test, SolverName)
            % Training the simplest kind of network gives the expected
            % accuracy.

            import  matlab.unittest.constraints.IsGreaterThan

            [XTrain, TTrain] = iLoadDigitTrainSet();

            layers = iSimpleMLPLayersForDigitTrainSetClassification();

            options = trainingOptions(SolverName, ...
                'MaxEpochs', 10, ...
                'Verbose', false, ...
                'ExecutionEnvironment', 'cpu');
            net = trainNetwork(XTrain, TTrain, layers, options);

            [XTest, TTest] = iLoadDigitTestSet();

            YTest = classify(net, XTest);
            accuracy = sum(YTest == TTest)/numel(TTest);

            test.verifyThat(accuracy, IsGreaterThan(0.62), "Validate correct accuracy from trained network");
        end
   
    end %methods
end %classdef

function layers = iSimpleMLPLayersForDigitTrainSetClassification()
layers = [ imageInputLayer([28 28 1])
    fullyConnectedLayer(10)
    softmaxLayer()
    classificationLayer()];
end

function [images, digits, angles] = iLoadDigitTrainSet()
data = load("digitTrainSet.mat");
images = data.images;
digits = data.digits;
angles = data.angles;
end

function [images, digits, angles] = iLoadDigitTestSet()
data = load("digitTestSet.mat");
images = data.images;
digits = data.digits;
angles = data.angles;
end

function solverNames = iGetSolverNames()
solverNames = {'sgdm','adam','rmsprop'};
end