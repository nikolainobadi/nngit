//
//  GitConfig.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

struct GitConfig: Codable {
    var branches: BranchSettings
    var loading: LoadingOptions
    var behaviors: BehaviorOptions

    init(branches: BranchSettings,
         loading: LoadingOptions = LoadingOptions(),
         behaviors: BehaviorOptions = BehaviorOptions()) {
        self.branches = branches
        self.loading = loading
        self.behaviors = behaviors
    }
    
    init(defaultBranch: String,
         rebaseWhenBranchingFromDefaultBranch: Bool,
         pruneWhenDeletingBranches: Bool = false,
         loadMergeStatusWhenLoadingBranches: Bool = true,
         loadCreationDateWhenLoadingBranches: Bool = true,
         loadSyncStatusWhenLoadingBranches: Bool = true) {
        self.branches = BranchSettings(defaultBranch: defaultBranch)
        self.loading = LoadingOptions(loadMergeStatus: loadMergeStatusWhenLoadingBranches,
                                    loadCreationDate: loadCreationDateWhenLoadingBranches,
                                    loadSyncStatus: loadSyncStatusWhenLoadingBranches)
        self.behaviors = BehaviorOptions(rebaseWhenBranchingFromDefault: rebaseWhenBranchingFromDefaultBranch,
                                       pruneWhenDeleting: pruneWhenDeletingBranches)
    }

    enum CodingKeys: String, CodingKey {
        case branches
        case loading
        case behaviors
        case defaultBranch
        case rebaseWhenBranchingFromDefaultBranch
        case pruneWhenDeletingBranches
        case loadMergeStatusWhenLoadingBranches
        case loadCreationDateWhenLoadingBranches
        case loadSyncStatusWhenLoadingBranches
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.branches) {
            branches = try container.decode(BranchSettings.self, forKey: .branches)
            loading = try container.decodeIfPresent(LoadingOptions.self, forKey: .loading) ?? LoadingOptions()
            behaviors = try container.decodeIfPresent(BehaviorOptions.self, forKey: .behaviors) ?? BehaviorOptions()
        } else {
            let defaultBranch = try container.decode(String.self, forKey: .defaultBranch)
            let rebaseWhenBranchingFromDefaultBranch = try container.decode(Bool.self, forKey: .rebaseWhenBranchingFromDefaultBranch)
            let pruneWhenDeletingBranches = try container.decodeIfPresent(Bool.self, forKey: .pruneWhenDeletingBranches) ?? false
            let loadMergeStatusWhenLoadingBranches = try container.decodeIfPresent(Bool.self, forKey: .loadMergeStatusWhenLoadingBranches) ?? true
            let loadCreationDateWhenLoadingBranches = try container.decodeIfPresent(Bool.self, forKey: .loadCreationDateWhenLoadingBranches) ?? true
            let loadSyncStatusWhenLoadingBranches = try container.decodeIfPresent(Bool.self, forKey: .loadSyncStatusWhenLoadingBranches) ?? true
            
            branches = BranchSettings(defaultBranch: defaultBranch)
            loading = LoadingOptions(loadMergeStatus: loadMergeStatusWhenLoadingBranches,
                                   loadCreationDate: loadCreationDateWhenLoadingBranches,
                                   loadSyncStatus: loadSyncStatusWhenLoadingBranches)
            behaviors = BehaviorOptions(rebaseWhenBranchingFromDefault: rebaseWhenBranchingFromDefaultBranch,
                                      pruneWhenDeleting: pruneWhenDeletingBranches)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(branches, forKey: .branches)
        try container.encode(loading, forKey: .loading)
        try container.encode(behaviors, forKey: .behaviors)
    }
}

extension GitConfig {
    static var defaultConfig: GitConfig {
        return .init(branches: BranchSettings(defaultBranch: "main"), loading: LoadingOptions(), behaviors: BehaviorOptions())
    }
}
