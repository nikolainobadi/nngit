//
//  GitFile.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker

/// Represents a template file that can be added to a Git repository.
struct GitFile: Codable, DisplayablePickerItem {
    let fileName: String
    let nickname: String
    let localPath: String
    
    init(fileName: String, nickname: String, localPath: String) {
        self.fileName = fileName
        self.nickname = nickname
        self.localPath = localPath
    }
    
    // MARK: - DisplayablePickerItem
    var displayName: String {
        return "\(nickname) (\(fileName))"
    }
}