//
//  BranchNameGenerator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

enum BranchNameGenerator {
    static func generate(
        name: String,
        branchPrefix: String? = nil,
        issueNumber: String? = nil,
        issueNumberPrefix: String? = nil
    ) -> String {
        var components: [String] = []

        if let branchPrefix, !branchPrefix.isEmpty {
            components.append(branchPrefix)
        }

        if let issueNumber, !issueNumber.isEmpty {
            if let prefix = issueNumberPrefix, !prefix.isEmpty {
                components.append(prefix + issueNumber)
            } else {
                components.append(issueNumber)
            }
        }

        let formattedBranchName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)

        components.append(formattedBranchName)

        return components.joined(separator: "/")
    }
}
