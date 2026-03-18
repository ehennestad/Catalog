function testToolbox(varargin)
    installMatBox("commit")
    projectRootDirectory = catalogtools.projectdir();
    matbox.tasks.testToolbox(projectRootDirectory, "SourceFolderName", "code", varargin{:})
end