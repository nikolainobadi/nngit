//
//  LoadingOptions.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

extension GitConfig {
    struct LoadingOptions: Codable {
        var loadMergeStatus: Bool
        var loadCreationDate: Bool
        var loadSyncStatus: Bool
        
        init(loadMergeStatus: Bool = true, loadCreationDate: Bool = true, loadSyncStatus: Bool = true) {
            self.loadMergeStatus = loadMergeStatus
            self.loadCreationDate = loadCreationDate
            self.loadSyncStatus = loadSyncStatus
        }
    }
}
