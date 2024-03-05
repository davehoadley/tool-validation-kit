classdef CombvecTests < matlab.unittest.TestCase
    % COMBVECTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
    
    methods(Test)
        %================================================
        function testLvlOneBasic(testCase)
            % Basic calculation

            a1 = [1 2 3; 4 5 6];
            a2 = [7 8; 9 10];
            x = combvec(a1,a2);
            expected = [1     2     3     1     2     3
                4     5     6     4     5     6
                7     7     7     8     8     8
                9     9     9    10    10    10];

            testCase.verifyEqual(x, expected, "Verify basic calculation.")
        end

        function testLvlOneEdgeCase(testCase)
            % example for edge case

            a=combvec([1 1]',1);
            expa=[1;1;1];

            testCase.verifyEqual(a, expa, "Verify edge case.")
        end
   
    end %methods
end %classdef