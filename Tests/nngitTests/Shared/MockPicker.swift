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
    
    private(set) var permissionResponses: [String: Bool]
    private(set) var requiredInputResponses: [String: String]
    private(set) var selectionResponses: [String: Int?]
    
    init(
        permissionResponses: [String: Bool] = [:],
        requiredInputResponses: [String: String] = [:],
        selectionResponses: [String: Int?] = [:]
    ) {
        self.permissionResponses = permissionResponses
        self.requiredInputResponses = requiredInputResponses
        self.selectionResponses = selectionResponses
    }
    
    // Helper methods for tests
    func addPermissionResponse(_ prompt: String, response: Bool) {
        permissionResponses[prompt] = response
    }
    
    func addBooleanResponse(_ prompt: String, response: Bool) {
        permissionResponses[prompt] = response
    }
    
    func addSelectionResponse(_ prompt: String, response: Int?) {
        selectionResponses[prompt] = response
    }
}


// MARK: - CommandLinePicker
extension MockPicker: CommandLinePicker {
    func getInput(prompt: PickerPrompt) -> String {
        return requiredInputResponses[prompt.title] ?? ""
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
        if let maybeIndex = selectionResponses[title.title] {
            if let index = maybeIndex, items.indices.contains(index) {
                return items[index]
            }
            return nil // User cancelled selection
        }
        
        return items.first
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: PickerPrompt, items: [Item]) throws -> Item {
        if let maybeIndex = selectionResponses[title.title], 
           let index = maybeIndex, 
           items.indices.contains(index) {
            return items[index]
        }
        return items[0]
    }
    
    func multiSelection<Item: DisplayablePickerItem>(title: PickerPrompt, items: [Item]) -> [Item] {
        if let maybeIndex = selectionResponses[title.title],
           let index = maybeIndex,
           items.indices.contains(index) {
            return [items[index]]
        }
        return []
    }
}
