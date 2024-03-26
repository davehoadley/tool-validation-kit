classdef ArithmeticTest < matlab.unittest.TestCase
% ARITHMETICTEST is an example validation test case for some features
% of the MATLAB language.  Specifically, it demonstrates basic math operators
% and functions for scalar, vector, and matrix data types.
% It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    methods(Test)
        function additionTest(testCase)
            arg1 = 11.4;
            arg2 = [-0.3, 44, pi];
            arg3 = [4, 5, 6.7; 0 - 3i, 99, 1.6e-3; 10, -90, 18];
            arg4 = -19.01;
            arg5 = [1/10, 3.21, -0.85];
            arg6 = [1, 2, 3; 4 + 2.5i, 5, 6; 9, 8, 7];
            
            sarg1 = single(0.001);
            sarg2 = single(5.211e2);
            
            iarg1 = int32(0);
            iarg2 = uint16([58; 2; 22]);
            iarg3 = int32(-101);
            
            testCase.verifyEqual(arg1 + arg4, -7.61, 'RelTol', eps, ...
                'Scalar sum incorrect');

            testCase.verifyEqual(arg1 + arg2, [11.1, 55.4, 14.541592653589793], ...
                'RelTol', eps, 'Vector + scalar sum incorrect');

            testCase.verifyEqual(arg1 + arg3, ...
                [15.4, 16.4, 18.1; 11.4 - 3i, 110.4, 11.4016; ...
                21.4, -78.6, 29.4], ...
                'RelTol', eps, 'Scalar + matrix sum incorrect');
            
            testCase.verifyEqual(arg2 + arg5, ...
                [-0.2, 47.21, 2.291592653589793], ...
                'RelTol', eps, 'Vector + vector sum incorrect');
            
            testCase.verifyEqual(arg3 + arg6, ...
                [5, 7, 9.7; 4 - 0.5i, 104, 6.0016; 19, -82, 25], ...
                'RelTol', eps, 'Matrix + matrix sum incorrect');

            result = csvread(fullfile('.','ArithmeticTest','AdditionTest.csv'),2,0);
            A = result(:,1);
            B = result(:,2);
            C = result(:,3);
            
            calc_sum = A + B;
            
            testCase.verifyEqual(C, calc_sum, 'RelTol', 1e-14, ...
                'sum incorrect');
        end

        function subtractionTest(testCase)
            % rather than inlining a list of constants for testing basic
            % arithmetic, read in a user-defined data file with
            % user-defined expected results
            result = csvread(fullfile('.','ArithmeticTest','SubtractionTest.csv'),2,0);
            A = result(:,1);
            B = result(:,2);
            C = result(:,3);
            
            calc_diff = A - B;
            
            testCase.verifyEqual(C, calc_diff, 'RelTol', 1e-14, ...
                'difference incorrect');
        end        
        function multiplicationTest(testCase)
            % rather than inlining a list of constants for testing basic
            % arithmetic, read in a user-defined data file with
            % user-defined expected results
            result = csvread(fullfile('.','ArithmeticTest','MultiplicationTest.csv'),2,0);
            A = result(:,1);
            B = result(:,2);
            C = result(:,3);
            
            calc_prod = A .* B;
            
            testCase.verifyEqual(C, calc_prod, 'RelTol', 1e-14, ...
                'product incorrect');
        end        
        function rightDivisionTest(testCase)
            % rather than inlining a list of constants for testing basic
            % arithmetic, read in a user-defined data file with
            % user-defined expected results
            result = csvread(fullfile('.','ArithmeticTest','RightDivisionTest.csv'),2,0);
            A = result(:,1);
            B = result(:,2);
            C = result(:,3);
            
            calc_div = A ./ B;
            
            testCase.verifyEqual(C, calc_div, 'RelTol', 1e-14, ...
                'divisor incorrect');
        end
        function roundTest(testCase)
            res = round(11.2);
            testCase.verifyEqual(res, 11, 'AbsTol', eps, ...
                'round incorrect');
            res = round(-9.9);
            testCase.verifyEqual(res, -10, 'AbsTol', eps, ...
                'round incorrect');
        end
        function hexConversionTest(testCase)
            res = hex2dec('80');
            testCase.verifyEqual(res, 128, 'AbsTol', eps, ...
                'hex2dec incorrect');

            res = hex2dec('D2');
            testCase.verifyEqual(res, 210, 'AbsTol', eps, ...
                'hex2dec incorrect');

            res = dec2hex(11);
            testCase.verifyEqual(res, 'B', ...
                'dec2hex incorrect');

            res = dec2hex(106);
            testCase.verifyEqual(res, '6A', ...
                'dec2hex incorrect');
        end            
    end
end