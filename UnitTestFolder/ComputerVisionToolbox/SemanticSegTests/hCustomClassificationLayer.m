classdef hCustomClassificationLayer < nnet.layer.ClassificationLayer
    % Copyright 2017-2018 The MathWorks, Inc.
    
    % custom classification layer used to test semanticseg.
    methods
        
        function loss = forwardLoss(~, Y, T)
            
            % Implement you loss here. Here we just replicate standard
            % cross-entropy.
            numObservations = size(Y, 4) * size(Y, 1) * size(Y, 2);
                       
            loss_i = T .* log(nnet.internal.cnn.util.boundAwayFromZero(Y));
            loss = -sum( sum( sum( sum(loss_i, 3).*(1./numObservations), 1), 2));
            
        end
        
        function dLdY = backwardLoss(~, Y, T)
            numObservations = size(Y, 4) * size(Y, 1) * size(Y, 2);
            dLdY = (-T./nnet.internal.cnn.util.boundAwayFromZero(Y)).*(1./numObservations);
        end
    end
end