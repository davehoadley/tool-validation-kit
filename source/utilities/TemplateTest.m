classdef TemplateTest < matlab.unittest.TestCase
    % TEMPLATETEST is an example validation test case for some features
    % of the MATLAB language.  This sample is intended to show how the user can
    % create additional tests to be executed.
    %
    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties
       %This section can be used to define test properties
    end

    %% Class and Method Setup
    methods(TestClassSetup)
        %This section can be used to define actions to execute before all
        %tests.
    end %methods

    methods(TestMethodSetup)
        %This section can be used to define actions to execute before each
        %test.
    end %methods
    
    methods(TestMethodTeardown)
        %This section can be used to define actions to execute after each
        %test.
    end %methods
    
    methods(TestClassTeardown)
        %This section can be used to define actions to execute after all
        %tests in this class have been completed.
    end %methods
    
    %% Test Methods
    methods(Test)

        function sampleTestPoint1(testCase)
            % This section should verify the expected results match the actual
            % results. 
            testCase.verifyEqual(1+1, 2, ...
                '1+1 did not equal 2');
            
            testCase.verifyEqual(2+2, 4, ...
                '2+2 did not equal 4');
        end %function
        
        function sampleTestPoint2(testCase)
            % A figure can show up in the final report
            testCase.fig = figure;
            t = 0:.01:2*pi;
            plot(2*cos(t));
            testCase.fig(end+1) = figure;
            plot(2*sin(t));
            
            % Error on purpose
            testCase.verifyEqual(1, 0, ...
                'An Example of Failing');
        end %function

    end %methods
end %classdef