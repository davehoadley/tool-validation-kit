classdef FakeTrainingPlotter < nnet.internal.cnn.ui.TrainingPlotter
    % FakeTrainingPlotter   Fake implementation of TrainingPlotter for testing trainingOptions function.
    
    %   Copyright 2019-2021 The MathWorks, Inc.
    
    methods
        function configure(~, ~)
        end
        
        function showPreprocessingStage(~, ~)
        end
        
        function showTrainingStage(~, ~)
        end
        
        function updatePlot(~, ~)
        end
        
        function updatePlotForLastIteration(~, ~)
        end
        
        function showPostTrainingStage(~, ~)
        end
        
        function showPlotError(~, ~)
        end
        
        function finalizePlot(~, ~)
        end
    end
end

