classdef TVKBase < handle
    %TVKBASE Class to handle running the tool validation kit
    %
    % tvk.TVKBase properties:
    %
    %   TestFolder              - test folder location
    %   EnableCustomReportGen   - flag to set custom report generation
    %   ReportFile              - generated report file name
    %   ResultsFolder           - result folder location
    %   TestTable               - high-level test table (Dependent)
    %   AllTestFiles            - list of all test files (Read-Only)
    %   SelectedTestFiles       - list of selected test files (Read-Only)
    %   ResultTable             - test suite results table after test execution (Read-Only)
    %   ProductsTested          - table of all products tested (Read-Only)
    %   DetailedTestTable       - detailed list of all test files in test table (Read-Only)
    %
    % tvk.TVKBase methods:
    %
    %   runTests                - generate test suite and run selected tests
    %   generateReport          - generate report after test suite is run
    %   selectTests             - select specific tests from test table
    %   getDetailedTestTable    - generate detailed test table from test suite
    %   createTestSuite         - create test suite from test list
    %
    % syntax:
    %
    %   tvkSession = tvk.TVKBase(testFolder, reportFolder);
    %
    %   MathWorks Consulting
    %   Copyright 2022-2024 The MathWorks Inc.

    %% Public Properties
    properties

        % Test folder location
        TestFolder (1,1) string = ""

        % Flag to set custom report generation
        EnableCustomReportGen (1,1) logical = true

        % Generated report file name
        ReportFile (1,1) string = "MATLAB_Tool_Validation_Report_" + datestr(datetime,30) + ".docx"

        % Result folder location
        ResultsFolder (1,1) string = ""

    end %properties

    %% Dependent Properties
    properties (Dependent)

        % High-level test table
        TestTable table

    end %propertiers

    %% Read-only Properties
    properties (SetAccess = private)

        % List of all test files
        AllTestFiles (:,1) string = ""

        % List of selected test files
        SelectedTestFiles (:,1) string = ""

        % Test suite results table after test execution
        ResultTable table = table()

        % Table of all products tested
        ProductsTested table = table()

        % Detailed list of all test files in test table
        DetailedTestTable table = table()

    end %properties

    %% Private Properties
    properties (Access = private)

        i_DiagnosticPlugin TVKDiagnosticRecorderPlugin

        i_DetailedTestTable table = table()

        i_TestSuite matlab.unittest.Test

    end %properties

    %% Constructor
    methods
        function obj = TVKBase(testFolder, resultsFolder)
            %TVKAPP Construct an instance of this class
            arguments
                testFolder (1,1) string
                resultsFolder (1,1) string = pwd
            end

            obj.TestFolder = testFolder;
            addpath(genpath(obj.TestFolder)) %make sure test folder and subfolders are on path

            % Create Test Suite
            obj.createTestSuite();

            % Select all tests
            obj.selectTests("all");

            % Get detailed test table
            obj.getDetailedTestTable();

            % Create report folder if it doesn't exist
            [~,~] = mkdir(resultsFolder);
            obj.ResultsFolder = resultsFolder;

        end %constructor
    end %methods

    %% Public Methods
    methods
        function runTests(obj)
            %RUNTESTS Generate test suite and run selected tests
            %
            % syntax:
            %
            %   tvkSession.runTests();
            %
            %   MathWorks Consulting
            %   Copyright 2022 The MathWorks Inc.

            import matlab.unittest.TestSuite
            import matlab.unittest.TestRunner
            import matlab.unittest.plugins.TestRunProgressPlugin
            import matlab.unittest.plugins.DiagnosticsRecordingPlugin
            import matlab.unittest.plugins.TestReportPlugin
            import matlab.unittest.plugins.ToFile

            cleanup = onCleanup(@() close('all'));

            if obj.SelectedTestFiles ~= ""

                %Run dependency analysis
                obj.runDependencyAnalysis();

                %Create runner
                runner = TestRunner.withTextOutput();

                if obj.EnableCustomReportGen
                    obj.i_DiagnosticPlugin = TVKDiagnosticRecorderPlugin;
                    runner.addPlugin(obj.i_DiagnosticPlugin);
                    runner.addPlugin(DiagnosticsRecordingPlugin(...
                        'IncludingPassingDiagnostics',true,...
                        'Verbosity',4));
                else
                    plugin = TestReportPlugin.producingDOCX(fullfile(obj.ResultsFolder, obj.ReportFile),...
                        'IncludingPassingDiagnostics',true, ...
                        'IncludingCommandWindowText',true);
                    runner.addPlugin(plugin);
                end

                progressplugin = TestRunProgressPlugin.withVerbosity(4);
                runner.addPlugin(progressplugin);

                % Filter existing test suite
                if isempty(obj.i_TestSuite)
                    obj.createTestSuite();
                end

                testClass = string([obj.i_TestSuite.TestClass]');
                tF = ismember(testClass, obj.TestTable.TestList(obj.TestTable.Selected));
                tsuite = obj.i_TestSuite(tF);

                % Run tests
                fprintf('Run selected test suite... \n')
                obj.ResultTable = table(run(runner, tsuite));
                obj.ResultTable.Duration = seconds(round(obj.ResultTable.Duration,4));
                fprintf('... Tests Complete.\n\n')

                % Join data from test suite and diagnostics plugin with
                % results table
                obj.ResultTable = addvars( obj.ResultTable, obj.DetailedTestTable.TestFolder, 'After','Name','NewVariableNames',{'BaseFolder'} );
                if obj.EnableCustomReportGen
                    dp = struct2table( obj.i_DiagnosticPlugin.TestData );
                    obj.ResultTable = join( dp, obj.ResultTable );
                end
                name = varfun( @(x) split(x,'/'),obj.ResultTable(:,1),'InputVariables','Name','OutputFormat','cell' );
                obj.ResultTable.Name = name{1};
                obj.ResultTable = splitvars( obj.ResultTable,'Name','NewVariableNames',{'ParentTest','Test'} );

                %Summarize results
                fprintf('Totals:\n')
                fprintf('    %d Passed, %d Failed, %d Incomplete.\n', ...
                    nnz(obj.ResultTable.Passed), nnz(obj.ResultTable.Failed), nnz(obj.ResultTable.Incomplete))
                fprintf('    %f seconds testing time.\n\n', seconds(sum(obj.ResultTable.Duration)))

            end %if

        end %function

        function generateReport(obj)
            %GENERATEREPORT Generate report after test suite is run
            %
            % syntax:
            %
            %   tvkSession.generateReport();
            %
            %   MathWorks Consulting
            %   Copyright 2022 The MathWorks Inc.

            if ~isempty(obj.ResultTable)
                if obj.EnableCustomReportGen

                    fprintf('Generating Custom Report... \n')

                    % Generate custom report using Report Gen
                    rpt = obj.genCustomTVKReport();

                    % Save report and print HTML link
                    fprintf('... Report Generation Complete\n')
                    cmd = ['"matlab:open(''', rpt.OutputPath, ''')"'];
                    disp(['<a href=',cmd,'>Report saved to: ' rpt.OutputPath '</a>'])

                else
                    if ismember("TestDiagnostic", string(obj.ResultTable.Properties.VariableNames))
                        warning("TVKBase:UnitTestFrameworkReport", "Results table contains test results with custom report generation enabled." + newline + ...
                            "Re-running tests to generate report from MATLAB Unit Test Framework")
                        obj.runTests();
                    else
                        warning('TVKBase:UnitTestFrameworkReport','Report already generated from MATLAB Unit Test Framework')
                    end
                end %if
            end %if
        end %function

        function selectTests(obj, inputTests)
            %SELECTTESTS Select specific tests from test table
            %
            % syntax:
            %
            %   tvkSession.selectTests("all");
            %   tvkSession.selectTests("none");
            %   tvkSession.selectTests(selectedTests);
            %
            %   MathWorks Consulting
            %   Copyright 2022 The MathWorks Inc.
            arguments
                obj
                inputTests (:,1) string {mustBeInTestList( ...
                    inputTests, obj)} = "all"
            end

            % Choose tests
            switch inputTests

                case "all"
                    obj.SelectedTestFiles = obj.AllTestFiles;

                case "none"
                    obj.SelectedTestFiles = "";

                otherwise
                    tF = ismember(obj.TestTable.TestList, inputTests);
                    obj.SelectedTestFiles = obj.AllTestFiles(tF);

            end %switch

            obj.getDetailedTestTable();

        end %function

        function getDetailedTestTable(obj)
            %GETDETAILEDTESTTABLE Generate detailed test table from test suite
            %
            % syntax:
            %
            %   tvkSession.getDetailedTestTable();
            %
            %   MathWorks Consulting
            %   Copyright 2022 The MathWorks Inc.

            if ~isempty(obj.i_TestSuite)

                result = table();

                testName = string({obj.i_TestSuite.ProcedureName})';
                testClass = string([obj.i_TestSuite.TestClass]');

                [~, baseFolder] = cellfun(@fileparts,{obj.i_TestSuite.BaseFolder}','UniformOutput',false);

                result.Test = testName;
                result.TestClass = testClass;
                result.TestFolder = string(baseFolder);

                tF = ismember(result.TestClass, obj.TestTable.TestList(obj.TestTable.Selected));
                result = result(tF, :);

                obj.DetailedTestTable = result;

            end %if

        end %function

        function createTestSuite(obj)
            %CREATETESTSUITE Create test suite from test list
            %
            % syntax:
            %
            %   tvkSession.createTestSuite();
            %
            %   MathWorks Consulting
            %   Copyright 2022 The MathWorks Inc.

            % Get test files
            obj.getAllTestFiles();

            % Create test suite once
            obj.i_TestSuite = testsuite(obj.AllTestFiles);

        end %function

    end %methods

    %% Methods in separate files
    methods (Access = private)
        rpt = genCustomTVKReport(obj)
    end %methods

    %% Private Methods
    methods (Access = private)
        function getAllTestFiles(obj)

            temp = dir(fullfile(obj.TestFolder,'**','*Test*.m'));
            temp([temp.isdir]) = [];
            obj.AllTestFiles = fullfile({temp.folder}',{temp.name}');

        end %function

        function runDependencyAnalysis(obj)

            fprintf('Performing dependency analysis to determine all the Toolboxes being tested...  \n')
            [~,productsTested] = matlab.codetools.requiredFilesAndProducts(obj.SelectedTestFiles);
            productsTested = struct2table(productsTested);
            productsTested.Certain = [];
            disp(productsTested)
            obj.ProductsTested = productsTested;
            fprintf('... Dependency analysis complete.\n\n')

        end %function

    end %methods

    %% Accessors
    methods

        function value = get.TestTable(obj)

            % Get test files
            obj.getAllTestFiles();

            [~, testList] = fileparts(obj.SelectedTestFiles);
            [~, parentList] = fileparts(fileparts(obj.AllTestFiles));
            [~, allTestList] = fileparts(obj.AllTestFiles);

            selected = ismember(allTestList, testList);

            value = table();

            value.TestList = allTestList;
            value.ParentList = parentList;
            value.Selected = selected;

        end %get.TestList

        function set.ReportFile(obj, value)
            
            if ~endsWith(value, ".docx")
                value = value + ".docx";
            end

            obj.ReportFile = value;

        end %set.ReportFile

        function set.EnableCustomReportGen(obj, value)

            if isempty(ver('rptgen'))
                warning("Report Generator Toolbox not installed." + newline + ...
                    "Setting report generation option to 0")
                value = false;
            end

            obj.EnableCustomReportGen = value;

        end %set.EnableCustomReportGen

    end %methods
end %classdef

%% Validators
function mustBeInTestList(input, obj)

mustBeMember(input, [obj.TestTable.TestList', "all", "none"])

end %function

