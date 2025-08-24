//
//  GitConfig.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

struct GitConfig: Codable {
    var defaultBranch: String
    var gitFiles: [GitFile]
    
    init(defaultBranch: String, gitFiles: [GitFile] = []) {
        self.defaultBranch = defaultBranch
        self.gitFiles = gitFiles
    }
}

extension GitConfig {
    static var defaultConfig: GitConfig {
        return .init(defaultBranch: "main", gitFiles: [])
    }
}
