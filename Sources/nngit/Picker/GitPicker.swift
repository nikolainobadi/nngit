//
//  GitPicker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 12/15/25.
//

import SwiftPickerKit

protocol GitPicker {
    func getInput(prompt: String) -> String
    func getPermission(prompt: String) -> Bool
    func requiredPermission(prompt: String) throws
    func getRequiredInput(prompt: String) throws -> String
    func singleSelection<Item: DisplayablePickerItem>(prompt: String, items: [Item], layout: PickerLayout<Item>, newScreen: Bool, showSelectedItemText: Bool) -> Item?
    func requiredSingleSelection<Item: DisplayablePickerItem>(prompt: String, items: [Item], layout: PickerLayout<Item>, newScreen: Bool, showSelectedItemText: Bool) throws -> Item
    func multiSelection<Item: DisplayablePickerItem>(prompt: String, items: [Item], layout: PickerLayout<Item>, newScreen: Bool, showSelectedItemText: Bool) -> [Item]
}

extension GitPicker {
    func getInput(_ prompt: String) -> String {
        return getInput(prompt: prompt)
    }
    
    func getRequiredInput(_ prompt: String) throws -> String {
        return try getRequiredInput(prompt: prompt)
    }
    
    func getPermission(_ prompt: String) -> Bool {
        return getPermission(prompt: prompt)
    }
    
    func requiredPermission(_ prompt: String) throws {
        try requiredPermission(prompt: prompt)
    }
    
    func singleSelection<Item: DisplayablePickerItem>(_ prompt: String, items: [Item], layout: PickerLayout<Item> = .singleColumn, newScreen: Bool = true, showSelectedItemText: Bool = false) -> Item? {
        return singleSelection(prompt: prompt, items: items, layout: layout, newScreen: newScreen, showSelectedItemText: showSelectedItemText)
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(_ prompt: String, items: [Item], layout: PickerLayout<Item> = .singleColumn, newScreen: Bool = true, showSelectedItemText: Bool = false) throws -> Item {
        return try requiredSingleSelection(prompt: prompt, items: items, layout: layout, newScreen: newScreen, showSelectedItemText: showSelectedItemText)
    }
    
    func multiSelection<Item: DisplayablePickerItem>(_ prompt: String, items: [Item], layout: PickerLayout<Item> = .singleColumn, newScreen: Bool = true, showSelectedItemText: Bool = false) -> [Item] {
        return multiSelection(prompt: prompt, items: items, layout: layout, newScreen: newScreen, showSelectedItemText: showSelectedItemText)
    }
}
