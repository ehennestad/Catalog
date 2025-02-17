function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = catalogtools.projectdir();
    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end