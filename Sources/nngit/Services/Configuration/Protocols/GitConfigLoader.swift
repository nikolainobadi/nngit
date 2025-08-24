//
//  GitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker

protocol GitConfigLoader {
    func save(_ config: GitConfig) throws
    func loadConfig(picker: CommandLinePicker) throws -> GitConfig
    func addGitFile(_ gitFile: GitFile, picker: CommandLinePicker) throws
    func removeGitFile(named fileName: String, picker: CommandLinePicker) throws -> Bool
}
