//
//  GitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import NnConfigKit

struct GitConfigLoader {
    private let manager = NnConfigManager<GitConfig>(projectName: "nngit")

    func load() throws -> GitConfig {
        return try manager.loadConfig()
    }

    func save(_ config: GitConfig) throws {
        try manager.saveConfig(config)
    }
}
