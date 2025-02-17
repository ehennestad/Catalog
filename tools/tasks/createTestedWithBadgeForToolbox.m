function createTestedWithBadgeForToolbox(versionNumber)
    arguments
        versionNumber (1,1) string
    end
    installMatBox()
    projectRootDirectory = catalogtools.projectdir();
    matbox.tasks.createTestedWithBadgeforToolbox(versionNumber, projectRootDirectory)
end