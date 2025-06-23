//
//  MockPicker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import SwiftPicker

final class MockPicker {
    private(set) var permissionPrompts: [String] = []
    private(set) var requiredPermissions: [String] = []
    
    var permissionResponses: [String: Bool] = [:]
    var requiredInputResponses: [String: String] = [:]
    var selectionResponses: [String: Int] = [:]
}


// MARK: - Picker
extension MockPicker: Picker {
    func getInput(prompt: PickerPrompt) -> String {
        // TODO: -
        return ""
    }
    
    func getRequiredInput(prompt: PickerPrompt) throws -> String {
        return requiredInputResponses[prompt.title] ?? ""
    }
    
    // permissions (y/n)
    func getPermission(prompt: PickerPrompt) -> Bool {
        permissionPrompts.append(prompt.title)
        return permissionResponses[prompt.title] ?? true
    }
    
    func requiredPermission(prompt: PickerPrompt) throws {
        requiredPermissions.append(prompt.title)
        if permissionResponses[prompt.title] == false {
            struct PermissionDenied: Error {}
            throw PermissionDenied()
        }
    }
    
    // selections
    func singleSelection<Item: DisplayablePickerItem>(title: PickerPrompt, items: [Item]) -> Item? {
        if let index = selectionResponses[title.title], items.indices.contains(index) {
            return items[index]
        }
        
        return items[0]
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: PickerPrompt, items: [Item]) throws -> Item {
        fatalError() // TODO: -
    }
    
    func multiSelection<Item: DisplayablePickerItem>(title: PickerPrompt, items: [Item]) -> [Item] {
        return [] // TODO: - 
    }
}
