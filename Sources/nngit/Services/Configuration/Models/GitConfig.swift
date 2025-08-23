//
//  GitConfig.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

struct GitConfig: Codable {
    var defaultBranch: String
    
    init(defaultBranch: String) {
        self.defaultBranch = defaultBranch
    }
}

extension GitConfig {
    static var defaultConfig: GitConfig {
        return .init(defaultBranch: "main")
    }
}
