//
//  MyBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Foundation
import SwiftPicker

/// Model representing a user-tracked git branch.
struct MyBranch: Codable {
    let name: String
    let createdDate: Date
    let description: String?
    
    init(name: String, description: String? = nil) {
        self.name = name
        self.createdDate = Date()
        self.description = description
    }
}

extension MyBranch: Equatable {
    static func == (lhs: MyBranch, rhs: MyBranch) -> Bool {
        return lhs.name == rhs.name
    }
}

extension MyBranch: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension MyBranch: DisplayablePickerItem {
    var displayName: String {
        if let description = description, description != name {
            return "\(name) - \(description)"
        }
        return name
    }
}