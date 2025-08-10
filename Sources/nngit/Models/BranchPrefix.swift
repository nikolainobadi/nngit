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
}

extension BranchPrefix: DisplayablePickerItem {
    /// String used when presenting this prefix in a picker.
    var displayName: String {
        guard requiresIssueNumber else {
            return name
        }

        return "\(name)/<issueNumber>"
    }
}
