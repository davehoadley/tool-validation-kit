function replaceClassNameWithFileName(filePath)
%REPLACECLASSNAMEWITHFILENAME Replace class name with file name
%
% Copyright 2022-2024 The MathWorks, Inc.

arguments
    filePath (1,1) string {mustBeFile}
end

[~, fname] = fileparts( filePath );

contents = string(fileread( filePath ));
className = extractBetween(contents, "classdef ", " <");

contents = strrep(string(contents), className, fname);
contents = strrep(string(contents), upper(className), upper(fname));
contents = convertStringsToChars(contents);

fID = fopen(filePath, 'w+');
fprintf(fID, "%s", contents);

fclose(fID);

end %function

