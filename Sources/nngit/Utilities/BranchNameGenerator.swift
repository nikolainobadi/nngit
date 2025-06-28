//
//  BranchNameGenerator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

/// Utility responsible for constructing fully qualified branch names.
///
/// The generator sanitizes the provided name and optionally prepends a branch
/// type and issue number components.
enum BranchNameGenerator {
    /// Generates a formatted branch name from the given components.
    /// - Parameters:
    ///   - name: The descriptive portion of the branch name.
    ///   - branchPrefix: Optional prefix describing the branch type, e.g.
    ///     `feature` or `bugfix`.
    ///   - issueNumber: Optional issue identifier to include in the branch name.
    ///   - issueNumberPrefix: Optional string that is prepended to the issue
    ///     number if one is provided.
    /// - Returns: A sanitized branch name joined using `/` separators.
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
