function codecheckToolbox()
    installMatBox()
    projectRootDirectory = catalogtools.projectdir();
    matbox.tasks.codecheckToolbox(projectRootDirectory)
end