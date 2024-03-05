classdef TVKDiagnosticRecorderPlugin < matlab.unittest.plugins.TestRunnerPlugin
    % This plugin captures diagnostic results as unit tests are run and
    % packages it to send to the reporting function
    %
    % Copyright 2022-2024 The MathWorks, Inc.
    
    %% Properties
    properties
        TestData
        Fig
    end
    
    %% Protected Methods
    methods (Access = protected)
        function runTest(plugin, pluginData)
            fprintf('### Running test: %s\n', pluginData.Name)
            
            runTest@matlab.unittest.plugins.TestRunnerPlugin(...
                plugin, pluginData);
        end %function
        
        function runTestSuite(plugin, pluginData)
            plugin.TestData = [];
            runTestSuite@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end %function
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            
            testName = pluginData.Name;
            testCase.addlistener('VerificationPassed', ...
                @(~,event)plugin.recordData(event,testName, 'PASSED', testCase));
            testCase.addlistener('VerificationFailed', ...
                @(~,event)plugin.recordData(event,testName, 'FAILED', testCase));
            testCase.addlistener('ExceptionThrown', ...
                @(~,event)plugin.recordData(event,testName, 'THREW EXCEPTION'));
        end %function
    end %methods
    
    %% Private Methods
    methods (Access = private)
        function recordData(plugin,eventData,name, failureType, testCase)
            import matlab.unittest.diagnostics.FigureDiagnostic
            
            s.Name = name;
            s.Type = failureType;
            s.TestDiagnostic = '';
            if ~isempty(eventData.TestDiagnostic)
                if isa(eventData.TestDiagnostic, "function_handle")
                    plugin.Fig = gcf;
                    clf(plugin.Fig,'reset');
                    eventData.TestDiagnostic();
                    testCase.log(4,FigureDiagnostic(plugin.Fig,'Formats',{'png'},'Prefix','Figure_'));
                else
                    s.TestDiagnostic = eventData.TestDiagnostic;
                end
            end 
            s.Stack = eventData.Stack;
            s.Timestamp = datetime;
            s.ActualValue = eventData.ActualValue;

            constraintClass = string(class(eventData.Constraint));

            s.ExpectedValue = [];
            s.Tolerance = [];
            s.CeilingValue = [];
            s.FloorValue = [];

            switch constraintClass

                case "matlab.unittest.constraints.IsEqualTo"
                    s.ExpectedValue = eventData.Constraint.Expected;
                    s.Tolerance = eventData.Constraint.Tolerance;

                case {"matlab.unittest.constraints.IsLessThan", "matlab.unittest.constraints.IsLessThanOrEqualTo"}
                    s.CeilingValue = eventData.Constraint.CeilingValue;

                case {"matlab.unittest.constraints.IsGreaterThan", "matlab.unittest.constraints.IsGreaterThanOrEqualTo"}
                    s.FloorValue = eventData.Constraint.FloorValue;

                case "matlab.unittest.constraints.IsTrue"
                    s.ExpectedValue = 1;
                
                case "matlab.unittest.constraints.IsFalse"
                    s.ExpectedValue = 0;

                case "matlab.unittest.constraints.IsOfClass"
                    s.ActualValue = class(eventData.ActualValue);
                    s.ExpectedValue = eventData.Constraint.Class;

                case "matlab.unittest.constraints.HasSize"
                    s.ActualValue = size(eventData.ActualValue);
                    s.ExpectedValue = eventData.Constraint.Size;

                case "matlab.unittest.constraints.IssuesNoWarnings"
                    if s.Type == "PASSED"
                        s.ActualValue = func2str(eventData.ActualValue) + " issued no warnings.";
                    else
                        s.ActualValue = func2str(eventData.ActualValue) + " issued warnings.";
                    end

                    s.ExpectedValue = func2str(eventData.ActualValue) + " issued no warnings.";

                case "matlab.unittest.constraints.Throws"
                    try
                        eventData.ActualValue()
                    catch ME
                        s.ActualValue = ME.identifier;
                    end
                    s.ExpectedValue = eventData.Constraint.ExpectedException;

            end %switch
            
            plugin.TestData = [plugin.TestData; s];

        end %function
    end %methods
end %classdef