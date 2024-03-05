classdef StatisticsMachineLearningTests < matlab.unittest.TestCase
    % STATISTICSMACHINELEARNINGTESTS contains validation test cases for some features
    % of the Statistics and Machine Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
    

    %% Test Methods
    methods(Test)
        function datasampleTest(testCase)
            %DATASAMPLETEST Unit tests for datasample()

            % LVLTWOVECTOR Test with row and column vector data

            rng(0,'twister');
            x = (1:5)';
            k = 3;
            y1 = datasample(x,k);
            y2 = datasample(x,k,1);
            y3 = datasample(x,1,2);
            y4 = datasample(x,1,3);
            testCase.verifyEqual(y1, x([5 5 1]), "Verify test with row and column vector data");
            testCase.verifyEqual(y2,x([5 4 1]), "Verify test with row and column vector data");
            testCase.verifyEqual(y3,x, "Verify test with row and column vector data");
            testCase.verifyEqual(y4,x, "Verify test with row and column vector data");

            % LVLTWOMATRIX Test with matrix data

            rng(0,'twister');
            x = reshape(1:25,5,5);
            k = 3;
            y1 = datasample(x,k);
            y2 = datasample(x,k,1);
            y3 = datasample(x,k,2);
            y4 = datasample(x,1,3);
            testCase.verifyEqual(y1,x([5 5 1],:), "Verify test with matrix data");
            testCase.verifyEqual(y2,x([5 4 1],:), "Verify test with matrix data");
            testCase.verifyEqual(y3,x(:,[2 3 5]), "Verify test with matrix data");
            testCase.verifyEqual(y4,x, "Verify test with matrix data");

           
            % LVLTWOREPLACE Test sampling with/without replacement

            % without replacement
            rng(0,'twister');
            x = reshape(1:25,5,5);
            k = 3;
            y1 = datasample(x,k,'replace',false);
            y2 = datasample(x,k,1,'replace',false);
            y3 = datasample(x,k,2,'replace',false);
            testCase.verifyEqual(y1,x([5 3 2],:), "Verify sample without replacement");
            testCase.verifyEqual(y2,x([1 4 5],:), "Verify sample without replacement");
            testCase.verifyEqual(y3,x(:,[4 3 5]), "Verify sample without replacement");

            % with replacement (explicitly)
            rng(0,'twister');
            k = 7;
            y1 = datasample(x,k,'replace',true);
            y2 = datasample(x,k,1,'replace',true);
            y3 = datasample(x,k,2,'replace',true);
            testCase.verifyEqual(y1,x([5 5 1 5 4 1 2],:), "Verify sample with replacement");
            testCase.verifyEqual(y2,x([3 5 5 1 5 5 3],:), "Verify sample with replacement");
            testCase.verifyEqual(y3,x(:,[5 1 3 5 4 5 4]), "Verify sample with replacement");

        end %function

        function rangeTest(testcase)
            %RANGETEST Unit tests for range()

            %% Test outputs for a variety of input shapes with a single input arg
            
            rng(0,'v5uniform');
            m = 6; n = 5; p = 2;
            x = rand(m,n,p);
            % this gives a nice pattern of NaNs to work with
            x(x(:) > .8) = NaN;
            x(:,2,1) = NaN;
            x(2,:,1) = NaN;
            
            % a column vector, some NaNs
            expR = 0.731511750;
            
            R = range(x(:,1,2));
            testcase.verifyEqual(R,expR,'RelTol',1e-9, "Verify column vector some Nans");
            
            % a column vector, all NaNs
            expR = NaN;
            
            R = range(x(:,2,1));
            testcase.verifyEqual(R,expR, "Verify column vector all Nans");
            
            % a row vector, some NaNs
            expR = 0.666003234;
            
            R = range(x(1,:,2));
            testcase.verifyEqual(R,expR,'RelTol',4e-10, "Verify row vector some Nans");
            
            % a row vector, all NaNs
            expR = NaN;
            
            R = range(x(2,:,1));
            testcase.verifyEqual(R,expR, "Verify row vector all Nans");
            
            % a matrix, some NaNs
            expR = [0.276114364 NaN 0.229440069 0.400408906 0.464901597];
            
            R = range(x(:,:,1));
            testcase.verifyEqual(R,expR,'RelTol',2e-9, "Verify matrix some Nans");
            
            %% Create some random data
            rng(0, 'twister');
            x = rand(4,3,2);
            
            % Test 'all'
            R0 = range(x(:));
            R1 = range(x,[1,2,3]);
            testcase.verifyEqual(R0,R1);
            R2 = range(x,'all');
            testcase.verifyEqual(R0,R2, "Verify 'all' N/V pair");
            
            % Test vector [1 2]
            R = range(x,[1,2]);
            expR = cat(3,0.873052376761206, 0.923780747818713);
            testcase.verifyEqual(R,expR,'AbsTol',5e-16, "Verify test vector [1 2]");
            
            % Test vector [2 3]
            R = range(x,[2 3]);
            expR = cat(1,0.535745552808023, 0.929176856625087, 0.722142489575271...
                , 0.828706443133400);
            testcase.verifyEqual(R,expR,'AbsTol',5e-16, "Verify test vector [2 3]");
            
            % Test vector [3 1]
            R = range(x,[3 1]);
            expR = cat(2,0.830180131949440, 0.861952021393493, 0.934881103186426);
            testcase.verifyEqual(R,expR,'AbsTol',5e-16, "Verify test vector [3 1]");

        end %function

    end %methods
end %classdef