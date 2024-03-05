classdef EvaluateSemanticSegmentationTests < matlab.unittest.TestCase
    % EVALUATESEMANTICSEGMENTATIONTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
    
    %% Properties
    properties
        imds
        pxdsResults
        pxdsTruth
        classNames
        labelIDs
    end %properties

    %% TestClassSetup Methods
    methods(TestClassSetup)
        function setup(testcase)

            import matlab.unittest.fixtures.WorkingFolderFixture;
            testcase.applyFixture(WorkingFolderFixture);

            % location of the triangleImages data set
            dataSetDir = fullfile(toolboxdir('vision'),'visiondata','triangleImages');
            % triangleImages test images
            testImagesDir = fullfile(dataSetDir,'testImages');
            % triangleImages ground truth labels
            testLabelsDir = fullfile(dataSetDir,'testLabels');
            % triangleImages class names and label IDs
            testcase.classNames = ["triangle", "background"];
            testcase.labelIDs = [255 0];
            % pxds for the true labels
            testcase.pxdsTruth = pixelLabelDatastore(testLabelsDir, ...
                testcase.classNames, testcase.labelIDs);
            % generate the predicted labels based on a pre-trained model
            net = load('triangleSegmentationNetwork.mat');
            testcase.imds = imageDatastore(testImagesDir);
            testcase.pxdsResults = semanticseg(testcase.imds,net.net, ...
                "WriteLocation", pwd);
        end
    end

    %% Test Methods
    methods(Test)
        function verifyMetricsObject(testcase)

            act = testcase.pxdsResults;
            exp = testcase.pxdsTruth;

            % default parameters
            metrics = evaluateSemanticSegmentation(act,exp);

            % verify ConfusionMatrix
            testcase.verifyClass(metrics.ConfusionMatrix,'table');
            rowNames = string(metrics.ConfusionMatrix.Row);
            testcase.verifyEqual(rowNames(:), testcase.classNames(:), "Verify ConfusionMatrix row names")
            colNames = string(metrics.ConfusionMatrix.Properties.VariableNames);
            testcase.verifyEqual(colNames(:), testcase.classNames(:), "Verify ConfusionMatrix column names")
            act_data = metrics.ConfusionMatrix.Variables;
            exp_data = [4730 0; 9601 88069];
            testcase.verifyEqual(act_data, exp_data, "Verify ConfusionMatrix data")

            % verify NormalizedConfusionMatrix
            testcase.verifyClass(metrics.NormalizedConfusionMatrix,'table');
            rowNames = string(metrics.NormalizedConfusionMatrix.Row);
            testcase.verifyEqual(rowNames(:), testcase.classNames(:))
            colNames = string(metrics.NormalizedConfusionMatrix.Properties.VariableNames);
            testcase.verifyEqual(colNames(:), testcase.classNames(:))
            act_data = metrics.NormalizedConfusionMatrix.Variables;
            num_data = sum(exp_data,2);
            for k = 1:size(exp_data,1)
                exp_data(k,:) = exp_data(k,:) / num_data(k);
            end
            testcase.verifyEqual(act_data, exp_data)

            % verify DataSetMetrics
            testcase.verifyClass(metrics.DataSetMetrics,'table');
            colNames = string(metrics.DataSetMetrics.Properties.VariableNames);
            exp_colNames = ["GlobalAccuracy","MeanAccuracy","MeanIoU","WeightedIoU","MeanBFScore"];
            testcase.verifyEqual(colNames(:), exp_colNames(:))
            testcase.verifyEqual(metrics.DataSetMetrics.GlobalAccuracy, 0.901, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.DataSetMetrics.MeanAccuracy,   0.948, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.DataSetMetrics.MeanIoU,        0.607, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.DataSetMetrics.WeightedIoU,    0.870, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.DataSetMetrics.MeanBFScore,    0.405, 'AbsTol', 1e-2)

            % verify ClassMetrics
            testcase.verifyClass(metrics.ClassMetrics,'table');
            colNames = string(metrics.ClassMetrics.Properties.VariableNames);
            exp_colNames = ["Accuracy","IoU","MeanBFScore"];
            testcase.verifyEqual(colNames(:), exp_colNames(:))
            rowNames = string(metrics.ClassMetrics.Row);
            testcase.verifyEqual(rowNames(:), testcase.classNames(:))
            testcase.verifyEqual(metrics.ClassMetrics.Accuracy,    [1.000;0.896], 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ClassMetrics.IoU,         [0.330;0.896], 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ClassMetrics.MeanBFScore, [0.028;0.782], 'AbsTol', 1e-2)

            % verify ImageMetrics
            testcase.verifyClass(metrics.ImageMetrics,'table');
            colNames = string(metrics.ImageMetrics.Properties.VariableNames);
            exp_colNames = ["GlobalAccuracy","MeanAccuracy","MeanIoU","WeightedIoU","MeanBFScore"];
            testcase.verifyEqual(colNames(:), exp_colNames(:))
            testcase.verifyEqual(metrics.ImageMetrics.GlobalAccuracy(1), 0.936, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ImageMetrics.MeanAccuracy(1),   0.967, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ImageMetrics.MeanIoU(1),        0.589, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ImageMetrics.WeightedIoU(1),    0.921, 'AbsTol', 1e-2)
            testcase.verifyEqual(metrics.ImageMetrics.MeanBFScore(1),    0.410, 'AbsTol', 1e-2)
        end %function

        function verifyMetricsParameter(testcase)
            % no metrics
            metrics_none = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "");
            testcase.verifyTrue(~isempty(metrics_none.ConfusionMatrix))
            testcase.verifyTrue(~isempty(metrics_none.NormalizedConfusionMatrix))
            testcase.verifyTrue(isempty(metrics_none.DataSetMetrics))
            testcase.verifyTrue(isempty(metrics_none.ClassMetrics))
            testcase.verifyTrue(isempty(metrics_none.ImageMetrics))

            % all
            metrics_all = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "all");
            exp_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth);
            testcase.verifyEqual(metrics_all.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(metrics_none.ConfusionMatrix, metrics_all.ConfusionMatrix)
            testcase.verifyEqual(metrics_all.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)
            testcase.verifyEqual(metrics_none.NormalizedConfusionMatrix, metrics_all.NormalizedConfusionMatrix)
            testcase.verifyEqual(metrics_all.DataSetMetrics, exp_metrics.DataSetMetrics)
            testcase.verifyEqual(metrics_all.ClassMetrics, exp_metrics.ClassMetrics)
            testcase.verifyEqual(metrics_all.ImageMetrics, exp_metrics.ImageMetrics)

            % accuracy
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "accuracy");

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),"MeanAccuracy")
            testcase.verifyEqual(act_metrics.DataSetMetrics.MeanAccuracy, exp_metrics.DataSetMetrics.MeanAccuracy)

            testcase.verifyEqual(string(act_metrics.ClassMetrics.Properties.VariableNames),"Accuracy")
            testcase.verifyEqual(act_metrics.ClassMetrics.Accuracy, exp_metrics.ClassMetrics.Accuracy)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),"MeanAccuracy")
            testcase.verifyEqual(act_metrics.ImageMetrics.MeanAccuracy, exp_metrics.ImageMetrics.MeanAccuracy)

            % bfscore
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "bfscore");

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),"MeanBFScore")
            testcase.verifyEqual(act_metrics.DataSetMetrics.MeanBFScore, exp_metrics.DataSetMetrics.MeanBFScore)

            testcase.verifyEqual(string(act_metrics.ClassMetrics.Properties.VariableNames),"MeanBFScore")
            testcase.verifyEqual(act_metrics.ClassMetrics.MeanBFScore, exp_metrics.ClassMetrics.MeanBFScore)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),"MeanBFScore")
            testcase.verifyEqual(act_metrics.ImageMetrics.MeanBFScore, exp_metrics.ImageMetrics.MeanBFScore)

            % global-accuracy
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "global");

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),"GlobalAccuracy")
            testcase.verifyEqual(act_metrics.DataSetMetrics.GlobalAccuracy, exp_metrics.DataSetMetrics.GlobalAccuracy)

            testcase.verifyEmpty(act_metrics.ClassMetrics)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),"GlobalAccuracy")
            testcase.verifyEqual(act_metrics.ImageMetrics.GlobalAccuracy, exp_metrics.ImageMetrics.GlobalAccuracy)

            % iou
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "iou");

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),"MeanIoU")
            testcase.verifyEqual(act_metrics.DataSetMetrics.MeanIoU, exp_metrics.DataSetMetrics.MeanIoU)

            testcase.verifyEqual(string(act_metrics.ClassMetrics.Properties.VariableNames),"IoU")
            testcase.verifyEqual(act_metrics.ClassMetrics.IoU, exp_metrics.ClassMetrics.IoU)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),"MeanIoU")
            testcase.verifyEqual(act_metrics.ImageMetrics.MeanIoU, exp_metrics.ImageMetrics.MeanIoU)

            % weighted-iou
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", "w");

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),"WeightedIoU")
            testcase.verifyEqual(act_metrics.DataSetMetrics.WeightedIoU, exp_metrics.DataSetMetrics.WeightedIoU)

            testcase.verifyEmpty(act_metrics.ClassMetrics)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),"WeightedIoU")
            testcase.verifyEqual(act_metrics.ImageMetrics.WeightedIoU, exp_metrics.ImageMetrics.WeightedIoU)

            % accuracy+iou
            act_metrics = evaluateSemanticSegmentation(testcase.pxdsResults, testcase.pxdsTruth, "Metrics", ["accuracy","iou"]);

            testcase.verifyEqual(act_metrics.ConfusionMatrix, exp_metrics.ConfusionMatrix)
            testcase.verifyEqual(act_metrics.NormalizedConfusionMatrix, exp_metrics.NormalizedConfusionMatrix)

            testcase.verifyEqual(string(act_metrics.DataSetMetrics.Properties.VariableNames),["MeanAccuracy" "MeanIoU"])
            testcase.verifyEqual(act_metrics.DataSetMetrics.MeanAccuracy, exp_metrics.DataSetMetrics.MeanAccuracy)
            testcase.verifyEqual(act_metrics.DataSetMetrics.MeanIoU, exp_metrics.DataSetMetrics.MeanIoU)

            testcase.verifyEqual(string(act_metrics.ClassMetrics.Properties.VariableNames),["Accuracy" "IoU"])
            testcase.verifyEqual(act_metrics.ClassMetrics.Accuracy, exp_metrics.ClassMetrics.Accuracy)
            testcase.verifyEqual(act_metrics.ClassMetrics.IoU, exp_metrics.ClassMetrics.IoU)

            testcase.verifyEqual(string(act_metrics.ImageMetrics.Properties.VariableNames),["MeanAccuracy" "MeanIoU"])
            testcase.verifyEqual(act_metrics.ImageMetrics.MeanAccuracy, exp_metrics.ImageMetrics.MeanAccuracy)
            testcase.verifyEqual(act_metrics.ImageMetrics.MeanIoU, exp_metrics.ImageMetrics.MeanIoU)
        end %function

    end %methods
end %classdef
