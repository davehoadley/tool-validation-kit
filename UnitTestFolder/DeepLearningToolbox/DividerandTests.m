classdef DividerandTests < matlab.unittest.TestCase
    % DIVIDERANDTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
   
    methods(Test)
        function testLvlOneBasic(testCase)
            % Basic calculation

            x = randperm(100);
            [x1,x2,x3,i1,i2,i3] = dividerand(x,0.6,0.2,0.2);
            [y1,y2,y3] = divideind(x,i1,i2,i3);
            xx = [x1 x2 x3];

            sorted1 = all(diff(i1)>0);
            sorted2 = all(diff(i2)>0);
            sorted3 = all(diff(i3)>0);

            testCase.verifyEqual(x1, y1, "Vectors for training is not equal to default value")
            testCase.verifyEqual(x2, y2, "Vectors for validation is not equal to default value")
            testCase.verifyEqual(x3, y3, "Vectors for testing is not equal to default value")
            testCase.verifyEqual(sort(x), sort(xx), "Concatenated vectors are not equal to default value")
            testCase.verifyEqual(sorted1, true, "Sorted vector for training is not equal to default value")
            testCase.verifyEqual(sorted2, true,  "Sorted vector for validation is not equal to default value")
            testCase.verifyEqual(sorted3, true, "Sorted vector for testing is not equal to default value")

        end %function

        function testLvlTwoCheckforOneInput(testCase)
            %  DIVIDERAND should work with default divide
            %  vector indices when no additional input parameters are supplied.

            rng(0,'twister')
            p = rands(3,1000);
            [~,~,~,trainInd,valInd,testInd] = dividerand(p);

            testCase.verifyEqual(size(trainInd,2)/size(p,2),.7, 'Ratio of vectors for training is not equal to default value')
            testCase.verifyEqual(size(valInd,2)/size(p,2),.15, 'Ratio of vectors for validation is not equal to default value')
            testCase.verifyEqual(size(testInd,2)/size(p,2),.15, 'Ratio of vectors for testing is not equal to default value')


            % Issue of how the training, testing
            % and validation data are divided: a call to ROUND is used when determining how
            % many vectors to put in each of the three sets (training, validation and test).

            p2 = rands(3,99);
            [~,~,~,trainInd2,valInd2,testInd2] = dividerand(p2,0.6,0.2,0.2);

            train_sample_size = size(trainInd2,2)/size(p2,2);
            val_sample_size = size(valInd2,2)/size(p2,2);
            test_sample_size = size(testInd2,2)/size(p2,2);

            testCase.verifyEqual(abs(train_sample_size - 0.6),.01, 'AbsTol', 0.01, 'Training sample size is not within one percentage point of ratio specified')
            testCase.verifyEqual(abs(val_sample_size - 0.2),.01,'AbsTol', 0.01, 'Validation sample size is not within one percentage point of ratio specified')
            testCase.verifyEqual(abs(test_sample_size - 0.2),.01, 'AbsTol', 0.01, 'Test sample size is not within one percentage point of ratio specified')

        end %function
    end %methods
end %classdef