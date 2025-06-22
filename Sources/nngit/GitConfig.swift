//
//  GitConfig.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

struct GitConfig: Codable {
    var defaultBranch: String
    var branchPrefixList: [BranchPrefix]
    var rebaseWhenBranchingFromDefaultBranch: Bool
}

extension GitConfig {
    static var defaultConfig: GitConfig {
        return .init(defaultBranch: "main", branchPrefixList: [], rebaseWhenBranchingFromDefaultBranch: true)
    }
}
