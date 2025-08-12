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
    ///   - issuePrefix: Optional prefix to prepend to the issue number (e.g., "FRA-", "RAPP-")
    /// - Returns: A sanitized branch name joined using `/` separators.
    static func generate(
        name: String,
        branchPrefix: String? = nil,
        issueNumber: String? = nil,
        issuePrefix: String? = nil
    ) -> String {
        var components: [String] = []

        if let branchPrefix, !branchPrefix.isEmpty {
            components.append(branchPrefix)
        }

        // Format issue with prefix if provided
        if let issueNumber, !issueNumber.isEmpty {
            if let issuePrefix, !issuePrefix.isEmpty {
                components.append("\(issuePrefix)\(issueNumber)")
            } else {
                components.append(issueNumber)
            }
        }

        // Only add the formatted branch name if it's not empty
        if !name.isEmpty {
            let formattedBranchName = name
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
            
            if !formattedBranchName.isEmpty {
                components.append(formattedBranchName)
            }
        }

        return components.joined(separator: "/")
    }
}
