//
//  NnGitPicker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPickerKit

protocol NnGitPicker {
    func getPermission(prompt: String) -> Bool
    func requiredPermission(prompt: String) throws
    func getRequiredInput(prompt: String) throws -> String
    func requiredSingleSelection<Item: DisplayablePickerItem>(
        prompt: String, items: [Item]
    ) throws -> Item
}
