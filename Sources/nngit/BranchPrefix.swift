//
//  BranchPrefix.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import Foundation
import SwiftPicker

struct BranchPrefix: Codable {
    let name: String
    let requiresIssueNumber: Bool
}

extension BranchPrefix: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}
