function packageToolbox(releaseType, versionString)
    arguments
        releaseType {mustBeTextScalar,mustBeMember(releaseType,["build","major","minor","patch","specific"])} = "build"
        versionString {mustBeTextScalar} = "";
    end
    installMatBox()
    projectRootDirectory = catalogtools.projectdir();
    matbox.tasks.packageToolbox(projectRootDirectory, releaseType, versionString)
end