function buildDocumentation()
% buildDocumentation - Build documentation from info.xml in this folder

prj = currentProject;
builddocsearchdb(fullfile(prj.RootFolder, "documentation", "LiveScriptsAndHTML"));
