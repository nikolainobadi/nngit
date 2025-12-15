//
//  GitFileCreator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

protocol GitFileCreator {
    func createGitFiles(_ gitFiles: [GitFile], destinationPath: String?) throws
    func createFile(named fileName: String, sourcePath: String, destinationPath: String?) throws
    func copyToTemplatesDirectory(sourcePath: String, fileName: String, picker: any GitPicker) throws -> String
}
