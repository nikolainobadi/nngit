//
//  GitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

protocol GitConfigLoader {
    func save(_ config: GitConfig) throws
    func loadConfig() throws -> GitConfig
    func addGitFile(_ gitFile: GitFile) throws
    func removeGitFile(named fileName: String) throws -> Bool
}
