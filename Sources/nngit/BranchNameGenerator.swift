//
//  BranchNameGenerator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker

enum BranchNameGenerator {
    static func generate(name: String, branchType: Nngit.NewBranch.BranchType?, issueNumber: Int?, config: GitConfig) throws -> String {
        var result = ""

        if let branchType {
            switch branchType {
            case .feature:
                result.append("feature/")
            case .bugfix:
                result.append("bugfix/")
            }
        }

        if let issueNumber {
            if let issueNumberPrefix = config.issueNumberPrefix {
                result.append("\(issueNumberPrefix)-")
            }
            result.append("\(issueNumber)/")
        }

        let formattedBranchName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)

        result.append(formattedBranchName)

        return result
    }
}

