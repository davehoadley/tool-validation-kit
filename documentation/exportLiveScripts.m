
%% Setup

prj = matlab.project.rootProject;
rootdir = prj.RootFolder;
docdir  = fullfile( rootdir, "documentation" );

%% Classes for documentation 

%m-code classdef files
classesForDocumentation = [...
    "tvk.TVKBase"
    ];

%mlx scripts
scriptsForDocumentation = matlab.io.datastore.DsFileSet( fullfile(docdir, "LiveScriptsAndHTML"), ...
            "FileExtensions", ".mlx", ...
            "IncludeSubfolders", true ).resolve.FileName;

%% Generate html doc from live editor scripts

for iScript = scriptsForDocumentation(:)'
    
    html = strrep(iScript,'.mlx','.html');    
    matlab.internal.liveeditor.openAndConvert( char(iScript), ...
        char(html));
end
    
%% Generate html on class documentation 

for iClass = classesForDocumentation(:)'
    
    thisFile = fullfile(docdir, "LiveScriptsAndHTML", "Classes", strcat(extractAfter(iClass, "tvk."),".html") );

    html = help2html( iClass, '-doc' );
    html = replaceBetween(html,"href=""", ".css"">", "../helpwin");
    html = replaceBetween(html,"<tr class=""subheader"">", "/tr>","", "Boundaries","inclusive");
    
    % Write the HTML file
    fid = fopen(thisFile,'w');
    fprintf(fid,'%s',html);
    fclose(fid);

end
