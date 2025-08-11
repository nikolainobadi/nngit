//
//  BranchSettings.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

extension GitConfig {
    struct BranchSettings: Codable {
        var defaultBranch: String
        var requireIssueForPrefixes: Bool
        
        init(defaultBranch: String, requireIssueForPrefixes: Bool = false) {
            self.defaultBranch = defaultBranch
            self.requireIssueForPrefixes = requireIssueForPrefixes
        }
    }
}
