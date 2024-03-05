function createNewTest(fileName, filePath)
%CREATENEWTEST Create new test file based on TemplateTest.m
%
% Copyright 2022-2024 The MathWorks, Inc.

arguments
    fileName (1,1) string
    filePath (1,1) string {mustBeFolder} = pwd
end

fullPath = fullfile(filePath, fileName);

templateTestPath = which("TemplateTest");
copyfile(templateTestPath, fullPath)

% Change class name to file name
replaceClassNameWithFileName( fullPath );

edit(fullPath)

end %function

