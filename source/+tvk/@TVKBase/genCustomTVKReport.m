function rpt = genCustomTVKReport(obj)
% This function accepts the results of a suite of unit tests and produces a
% report using the Reporter API in the MATLAB Report Generator
% 
% Copyright 2022-2024 The MathWorks, Inc.

rptfile = fullfile(obj.ResultsFolder, obj.ReportFile);
testedprod = obj.ProductsTested;
result = obj.ResultTable;

format long
%% Import report gen API and initialize report
import mlreportgen.report.*
import mlreportgen.dom.*
rpt = Report(rptfile,'docx');

%% Insert title page
tp = TitlePage;
tp.Title = 'MATLAB® TOOL VALIDATION REPORT';
tp.Subtitle = 'CLIENT_NAME';
calldir = fileparts(mfilename('fullpath'));
rootDir = fullfile(calldir, "..", "..", "..");
tp.Image = fullfile(rootDir, "icons", "logopic.png");
tp.Author = 'MathWorks';
tp.PubDate = string(datetime);
add(rpt,tp);

%% Insert signatures table
ftable = createSigTable();
bt = BaseTable(ftable);
bt.TableStyleName = 'Plain Table 2';
bt.TableWidth = '100%';
add(rpt,bt)

add(rpt,PageBreak)

%% Insert table of contents
toc = TableOfContents();
toc.Title = Text('Table of Contents');
toc.TOCObj.NumberOfLevels = 2; 
add(rpt,toc);

%% Insert introduction/declaration chapter
ch = Chapter;
ch.Title = 'Introduction';

% introfolder = fullfile(calldir,'IntroductionFiles');
introfolder = fullfile(rootDir, "documents", "IntroductionFiles");
introfiles = cellfun(@(x) fullfile(introfolder,x),cellstr(ls(fullfile(introfolder,'*.txt'))),'UniformOutput',false);
for ii = 1:numel(introfiles)
    text = fileread(introfiles{1});
    [~,introfilename] = fileparts(introfiles{ii});
    introfilename = extractAfter(introfilename,'_');
    sec = Section;
    sec.Title = introfilename;
    para = Paragraph(sprintf(text));
    para.WhiteSpace = 'preserve';
    add(sec,para)
    add(ch,sec)
end

add(rpt,ch)

%% Insert tool validation overview chapter
ch = Chapter();
ch.Title = sprintf('MATLAB® Tool Validation Overview');

%% Ch1. Section1. Test summary
ftable = createEnvTable();
bt = BaseTable(ftable);
bt.TableStyleName = 'Plain Table 2';
bt.TableWidth = '100%';
add(ch,bt)

ftable = createSumTable(height(result),...
    sum(result.Duration),...
    all(result.Passed));
bt = BaseTable(ftable);
bt.TableStyleName = 'Plain Table 2';
bt.TableWidth = '100%';
add(ch,bt)

fig = Figure(createPieChart(result));
add(ch,fig)

add(ch,PageBreak)

%% Ch1. Section2. Products tested
sec = Section;
sec.Title = 'Products Tested';
ftable = createProductTable(testedprod);
bt = BaseTable(ftable);
bt.TableStyleName = 'Plain Table 2';
bt.TableWidth = '100%';
add(sec,bt)
add(ch,sec)

%% Ch1. Section3. Individual Test Results Summary
sec = Section();
sec.Title = 'Tool Validation Test Results Summary';
uniquebase = unique(result.BaseFolder);
for bb = 1:numel(uniquebase)
    thisbase = uniquebase{bb};
    basetxt = Text(thisbase);
    basetxt.Bold = true;
    basetxt.FontSize = '14pt';
    body = {basetxt,Text()};
    inbase = ismember(result.BaseFolder,thisbase);
    uniqueparent = unique(result.ParentTest(inbase));
    for pp = 1:numel(uniqueparent)
        thisparent = uniqueparent{pp};
        parenttxt = Text(thisparent);
        parenttxt.Italic = true;
        parenttxt.FontSize = '12pt';
        body(end+1,:) = {parenttxt,Text()};
        inparent = ismember(result.ParentTest,thisparent);
        passfailstring = Paragraph();
        for kk = find(inparent)'
            if result.Passed(kk)
                otext = Text('O');
                otext.Color = 'green';
                append(passfailstring,otext);
            else
                xtext = Text('X');
                xtext.Color = 'red';
                xtext.Bold = true;
                append(passfailstring,xtext);
            end
        end
        body(end+1,:) = {passfailstring,Text(string(sum(result.Duration(inparent))))};
    end
    t = Table(body);
    add(sec,t)
end
add(ch,sec)
add(rpt,ch);

%% Insert tool validation result details chapter
ch = Chapter();
ch.Title = 'Tool Validation Test Details';

%% Ch2. Section n. Individual Test details
uniqueparent = unique(result.ParentTest);
for pp = 1:numel(uniqueparent)
    thisparent = uniqueparent{pp};
    sec = Section();
    sec.Title = thisparent;
    
    inparent = ismember(result.ParentTest,thisparent);
    uniquetest = unique(result.Test(inparent));
    for tt = 1:numel(uniquetest)
        thistest = uniquetest{tt};
        testnametxt = Heading(3,thistest,'SectionTitle3');
        testnametxt.Bold = true;
        testnametxt.Italic = true;
        testnametxt.FontSize = '12pt';
        add(sec,testnametxt);
        
        intest = ismember(result.Test,thistest) & inparent;
        if all(result.Passed(intest))
            passfail = 'passed';
        else
            passfail = 'failed';
        end
        testinfo = Text(sprintf('This test %s.  Duration: %s',passfail,string(result.Duration(tt))));
        testinfo.WhiteSpace = 'preserve';
        add(sec,testinfo)
        
        idx = find(intest,1);
        diagrecnum = numel(result.Details{idx}.DiagnosticRecord);
        diagrec = {};
        for didx = 1:diagrecnum
            if contains(class(result.Details{idx}.DiagnosticRecord(didx)),'Qualification')
                diagrec{end+1} = result.Details{idx}.DiagnosticRecord(didx); %#ok<*AGROW> 
            end
        end
        
        figdetails = result.Details{idx}.DiagnosticRecord(string({result.Details{idx}.DiagnosticRecord.Event})=='DiagnosticLogged');
        if ~isempty(figdetails)
            for fidx = 1:numel(figdetails)
                imgObj = FormalImage(char(figdetails(fidx).LoggedDiagnosticResults.Artifacts.FullPath));
                imgObj.Width = '4in';
                add(sec,imgObj)
            end
        end
        
        didx = find(intest);
        for dd = 1:nnz(intest)
            thisdiag = result(didx(dd),:);
            
            if ~isempty(thisdiag.TestDiagnostic{1})% && ischar(thisdiag.TestDiagnostic{1})  
                eventtitle = Text(thisdiag.TestDiagnostic{1});
            elseif isa(thisdiag.TestDiagnostic{1},'function_handle')
                eventtitle = Text(func2str(thisdiag.TestDiagnostic{1}));
            else
                eventtitle = Text('Untitled Test event');
            end
            eventtitle.Bold = true;
            add(sec,eventtitle)
            
            if ~isempty(diagrec)
                txt = splitlines(diagrec{dd}.FrameworkDiagnosticResults.DiagnosticText);
                indices = find(contains(txt,'Actual'));
                if ~isempty(indices)
                    txt = txt(1:indices(1)-1);
                    str = join(txt,newline);
                else
                    str = {''};
                end
                diagcontent = Text(sprintf(str{:}));
                diagcontent.FontFamilyName = 'Courier New';
                diagcontent.WhiteSpace = 'preserve';
                diagcontent.FontSize = '8pt';
                add(sec,diagcontent)
            end

            actval = thisdiag.ActualValue;
            if isa(actval,'cell')
                if numel(actval) > 1
                    actval = [actval{:}];
                else
                    actval = actval{:};
                end

            end

             if isa(actval, "function_handle")
                    actval = {actval};
             end

            if isa(actval, "char")
                actval = string(actval);
            end
            if isempty(actval)
                actval = [];
            end

            expval = thisdiag.ExpectedValue;
            if isa(expval,'cell')
                if numel(actval) > 1
                    expval = [expval{:}];
                else
                    expval = expval{:};
                end

                if isa(expval, "function_handle")
                    expval = {expval};
                end

                if isa(expval, "char")
                    expval = string(expval);
                end
                if isempty(expval)
                    expval = [];
                end
            end
            
            if ismatrix(actval) && ~isempty(expval) && ~contains(class(actval),'table')

                if size(actval,2) ~= size(expval,2) || size(actval,1) ~= size(expval,1)
                    expvaltxt = Text(sprintf(['\n',...
                        '---------------------\n',...
                        'Size of Actual Value matrix and Expected Value matrix did not match!\n',...
                        '---------------------\n']));
                    expvaltxt.WhiteSpace = 'preserve';
                    expvaltxt.FontFamilyName = 'Courier New';
                    expvaltxt.FontSize = '8pt';
                    add(sec,expvaltxt)
                else
                    if size(actval,2)>size(actval,1)
                        tbl = MATLABTable(table(actval',expval','VariableNames',{'ActualValue','ExpectedValue'}));
                    else
                        tbl = MATLABTable(table(actval,expval,'VariableNames',{'ActualValue','ExpectedValue'}));
                    end
                    tbl.Style = {FontFamily('Courier New'),FontSize('8pt')};
                    bt = BaseTable(tbl);
                    add(sec,bt)
                end
                
            elseif isnumeric(actval)
                actvaltxt = Text(sprintf(['\n',...
                    '---------------------\n',...
                    'Actual Value:\n',...
                    '---------------------\n\n',...
                    '    %.7g\n'],actval));
                actvaltxt.WhiteSpace = 'preserve';
                actvaltxt.FontFamilyName = 'Courier New';
                actvaltxt.FontSize = '8pt';
                add(sec,actvaltxt)
                
                if ~isempty(expval)
                    expvaltxt = Text(sprintf(['\n',...
                        '---------------------\n',...
                        'Expected Value:\n',...
                        '---------------------\n\n',...
                        '    %.7g\n'],expval));
                    expvaltxt.WhiteSpace = 'preserve';
                    expvaltxt.FontFamilyName = 'Courier New';
                    expvaltxt.FontSize = '8pt';
                    add(sec,expvaltxt)
                end
            elseif contains(class(actval),'table')
                actvaltxt = Text(sprintf(['\n',...
                    '---------------------\n',...
                    'Actual Value:\n',...
                    '---------------------\n']));
                actvaltxt.WhiteSpace = 'preserve';
                actvaltxt.FontFamilyName = 'Courier New';
                actvaltxt.FontSize = '8pt';
                add(sec,actvaltxt)

                tbl = MATLABTable(actval);

                tbl.Style = {FontFamily('Courier New'),FontSize('8pt')};
                bt = BaseTable(tbl);
                add(sec,bt)
                
                if ~isempty(expval)
                    expvaltxt = Text(sprintf(['\n',...
                        '---------------------\n',...
                        'Expected Value:\n',...
                        '---------------------\n']));
                    expvaltxt.WhiteSpace = 'preserve';
                    expvaltxt.FontFamilyName = 'Courier New';
                    expvaltxt.FontSize = '8pt';
                    add(sec,expvaltxt)
                    tbl = MATLABTable(expval);
                    tbl.Style = {FontFamily('Courier New'),FontSize('8pt')};
                    bt = BaseTable(tbl);
                    add(sec,bt)
                end
            end
            
            if isnumeric(thisdiag.CeilingValue) || ~isempty(thisdiag.CeilingValue{:})
                tolvar = 'UpperBound';
                if isnumeric(thisdiag.CeilingValue)
                    tolval = thisdiag.CeilingValue;
                else
                    tolval = thisdiag.CeilingValue{:};
                end
            elseif isnumeric(thisdiag.FloorValue) || ~isempty(thisdiag.FloorValue{:})
                tolvar = 'LowerBound';
                if isnumeric(thisdiag.FloorValue)
                    tolval = thisdiag.FloorValue;
                else
                    tolval = thisdiag.FloorValue{:};
                end
            elseif isnumeric(thisdiag.Tolerance) || ~isempty(thisdiag.Tolerance(:))
                tolvar = thisdiag.Tolerance;
                while isa(tolvar,'cell')
                    tolvar = tolvar{:};
                end
                if isempty(tolvar)
                    tolval = [];
                    tolvar = 'Tolerance';
                else
                    tolval = tolvar.Values{:};
                    tolvar = extractAfter(class(tolvar),'constraints.');
                end
            else
                tolvar = 'Tolerance';
                tolval = [];
            end
            
            if ~isempty(tolval)
                toltxt = Text(sprintf(['\n',...
                    '---------------------\n',...
                    tolvar,':\n',...
                    '---------------------\n\n',...
                    '    %.7g\n'],tolval));
                toltxt.WhiteSpace = 'preserve';
                toltxt.FontFamilyName = 'Courier New';
                toltxt.FontSize = '8pt';
                add(sec,toltxt)
            end
        end
    end
    add(ch,sec)
end

add(rpt,ch);
format short

close(rpt)
end

function ftable = createSigTable()
import mlreportgen.report.*
import mlreportgen.dom.*

tbtitle = Text('Signatures:');
tbtitle.Bold = true;
tbtitle.FontSize = '16pt';
txt = Text(sprintf('Signature:\t_________________________________________________'));
txt.WhiteSpace = 'preserve';
authortxt = Text(sprintf('Author:\t\t_________________________________________________'));
authortxt.WhiteSpace = 'preserve';
sysownertxt = Text(sprintf('System Owner:\t_________________________________________________'));
sysownertxt.WhiteSpace = 'preserve';
qatxt = Text(sprintf('Quality Assurance:______________________________________________'));
qatxt.WhiteSpace = 'preserve';

tbcontent = {authortxt,Text();...
    clone(txt),Text('Date:_____________');...
    Text(),Text();...
    sysownertxt,Text();...
    clone(txt),Text('Date:_____________');...
    Text(),Text();...
    qatxt,Text();...
    clone(txt),Text('Date:_____________')};
ftable = FormalTable({tbtitle,Text()},tbcontent);
ftable.Border = 'double';
end

function ftable = createEnvTable()
import mlreportgen.report.*
import mlreportgen.dom.*

tbtitle = Text('Test Environment');
tbtitle.Bold = true;
tbtitle.FontSize = '16pt';

timestamp = Text('Timestamp:');
timestamp.Style = {HAlign('right')};
timestamp.Bold = true;
hostname = Text('Hostname:');
hostname.Style = {HAlign('right')};
hostname.Bold = true;
platform = Text('Platform:');
platform.Style = {HAlign('right')};
platform.Bold = true;
mlver = Text('MATLAB Version:');
mlver.Style = {HAlign('right')};
mlver.Bold = true;

tbcontent = {timestamp,Text(char(datetime));...
    hostname,Text(getenv('COMPUTERNAME'));...
    platform,Text(computer);...
    mlver,Text(version)};
ftable = FormalTable({tbtitle,Text()},tbcontent);
ftable.Border = 'none';
end

function ftable = createSumTable(tnum,ttime,tresult)
import mlreportgen.report.*
import mlreportgen.dom.*

tbtitle = Text('Test Summary');
tbtitle.Bold = true;
tbtitle.FontSize = '16pt';

testnum = Text('Number of Tests:');
testnum.Style = {HAlign('right')};
testnum.Bold = true;
testtime = Text('Testing Time:');
testtime.Style = {HAlign('right')};
testtime.Bold = true;
overallresult = Text('Overall Result:');
overallresult.Style = {HAlign('right')};
overallresult.Bold = true;

if tresult
    passfail = 'PASSED';
else
    passfail = 'FAILED';
end

tbcontent = {testnum,Text(tnum);...
    testtime,Text(string(ttime));...
    overallresult,Text(passfail)};
ftable = FormalTable({tbtitle,Text()},tbcontent);
ftable.Border = 'none';
end

function ftable = createProductTable(p)
import mlreportgen.report.*
import mlreportgen.dom.*

ftable = MATLABTable(p(:,1:3));
ftable.Border = 'none';
end

function fig = createPieChart(result)
pass = sum(result.Passed)/height(result);
fail = 1-pass;

if fail == 0
    X = pass;
    explode = 0;
    labels = {'PASSED'};
elseif pass == 0
    X = fail;
    explode = 0;
    labels = {'FAILED'};
else
    X = [pass,fail];
    explode = [0,1];
    labels = {'PASSED','FAILED'};
end

fig = figure;
fig.Visible = 'off';
fig.Color = [1,1,1];
a = axes(fig);
p = pie(a,X,explode);
p(1).FaceColor = [0 1 0];
if numel(p)>2
    p(3).FaceColor = [1 0 0];
end
legend(labels,'location','EastOutside')
end