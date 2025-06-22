//
//  BranchNameGenerator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker

enum BranchNameGenerator {
    static func generate(name: String, config: GitConfig) throws -> String {
        var result = ""

        let formattedBranchName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)

        result.append(formattedBranchName)

        return result
    }
}
