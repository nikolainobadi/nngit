protocol GitFileCreator {
    func createFile(named fileName: String, sourcePath: String, destinationPath: String?) throws
    func createGitFiles(_ gitFiles: [GitFile], destinationPath: String?) throws
}