classdef ComputationalGeometryTests < matlab.unittest.TestCase
    % COMPUTATIONALGEOMETRYTESTS is an example validation test case for some features
    % of the MATLAB language.  This sample is intended to show how the user can
    % create additional tests to be executed.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties
        %This section can be used to define test properties
        P double
        T double
    end

    %% Class and Method Setup
    methods(TestClassSetup)
        %This section can be used to define actions to execute before all
        %tests.
        function setup(testCase)
            testCase.P = [2.5 8.0; 6.5 8.0; 2.5 5.0; 6.5 5.0; 1.0 6.5; 8.0 6.5];
            testCase.T = [5 3 1; 3 2 1; 3 4 2; 4 6 2];
        end %function

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

        function testTriangulation(testCase)
            % Unit tests for triangulation()

            TR = triangulation(testCase.T, testCase.P);

            coordsAct = TR.Points(TR.ConnectivityList(1,:),:);

            coordsExp = [
                1.0000    6.5000
                2.5000    5.0000
                2.5000    8.0000];

            testCase.verifyEqual(coordsAct, coordsExp, "AbsTol", 0.01, "Verify coordinates of the vertices of the first triangle")

        end %function

        function testSTLWrite(testCase)
            % Unit test for stlwrite()

            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture);

            stlFilePath = fullfile(mfilename("fullpath"), "tritext.stl");

            diaryExp = fileread(stlFilePath);

            TR = triangulation(testCase.T, testCase.P);

            stlwrite(TR,'tritext.stl','text');

            stlNewFilePath = fullfile(pwd, "tritext.stl");

            diaryAct = fileread(stlNewFilePath);

            % handle cross-platform CRLF issue
            diaryAct = strrep(diaryAct, [char(13) newline], newline);
            diaryExp = strrep(diaryExp, [char(13) newline], newline);

            testCase.verifyEqual(diaryAct, diaryExp, "Verify successful write of STL file from triangulation")

        end %function

    end %methods
end %classdef