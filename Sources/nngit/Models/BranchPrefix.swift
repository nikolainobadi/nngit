//
//  BranchPrefix.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import Foundation
import SwiftPicker

/// Model representing a branch name prefix configuration.
struct BranchPrefix: Codable {
    let name: String
    let requiresIssueNumber: Bool
    let issuePrefixes: [String]
    let defaultIssueValue: String?
    
    /// Creates a new BranchPrefix with modern issue handling
    init(name: String, requiresIssueNumber: Bool, issuePrefixes: [String] = [], defaultIssueValue: String? = nil) {
        self.name = name
        self.requiresIssueNumber = requiresIssueNumber
        self.issuePrefixes = issuePrefixes
        self.defaultIssueValue = defaultIssueValue
    }
    
    /// Legacy initializer for backwards compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.requiresIssueNumber = try container.decode(Bool.self, forKey: .requiresIssueNumber)
        self.issuePrefixes = try container.decodeIfPresent([String].self, forKey: .issuePrefixes) ?? []
        self.defaultIssueValue = try container.decodeIfPresent(String.self, forKey: .defaultIssueValue)
    }
}

extension BranchPrefix: DisplayablePickerItem {
    /// String used when presenting this prefix in a picker.
    var displayName: String {
        guard requiresIssueNumber else {
            return name
        }
        
        if !issuePrefixes.isEmpty {
            let prefixExamples = issuePrefixes.prefix(2).joined(separator: "|")
            return "\(name)/[\(prefixExamples)]<issue>"
        }

        return "\(name)/<issueNumber>"
    }
}
