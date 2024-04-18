function plan = buildfile
import matlab.buildtool.tasks.*

plan = buildplan(localfunctions);

plan("clean") = CleanTask;

plan("check") = CodeIssuesTask(...
    Results="analysis-results/codeIssues.sarif",...
    WarningThreshold=38);

plan("test") = TestTask(...
    SourceFiles="source", ...
    TestResults=["test-results/results.xml" "test-results/test-report.html"], ...
    LoggingLevel="detailed") ...
    .addCodeCoverage(...
        ["test-results/coverage.xml", "test-results/coverage-report/index.html"], ...
        MetricLevel="mcdc");

plan("toolbox").Dependencies = ["check" "test"];
plan("toolbox").Inputs = plan.RootFolder;
plan("toolbox").Outputs = "release/Tool Validation Kit.mltbx";

plan.DefaultTasks = ["check" "test"];
end

function toolboxTask(ctx)
opts = matlab.addons.toolbox.ToolboxOptions(ctx.Plan.RootFolder,"266fc400-0ecc-42c5-ad93-c19364dbaf03", ...
    ToolboxVersion="4.2.1", ...
    AuthorName="MathWorks Consulting", ...
    AuthorCompany="MathWorks, Inc.", ...
    MinimumMatlabRelease="R2024a", ...
    OutputFile=ctx.Task.Outputs.paths);

matlab.addons.toolbox.packageToolbox(opts);
end