//
//  GitConfig.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

struct GitConfig: Codable {
    var defaultBranch: String
    var branchPrefixList: [BranchPrefix]
    var rebaseWhenBranchingFromDefaultBranch: Bool
    var pruneWhenDeletingBranches: Bool

    init(defaultBranch: String,
         branchPrefixList: [BranchPrefix],
         rebaseWhenBranchingFromDefaultBranch: Bool,
         pruneWhenDeletingBranches: Bool = false) {
        self.defaultBranch = defaultBranch
        self.branchPrefixList = branchPrefixList
        self.rebaseWhenBranchingFromDefaultBranch = rebaseWhenBranchingFromDefaultBranch
        self.pruneWhenDeletingBranches = pruneWhenDeletingBranches
    }

    enum CodingKeys: String, CodingKey {
        case defaultBranch
        case branchPrefixList
        case rebaseWhenBranchingFromDefaultBranch
        case pruneWhenDeletingBranches
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultBranch = try container.decode(String.self, forKey: .defaultBranch)
        branchPrefixList = try container.decode([BranchPrefix].self, forKey: .branchPrefixList)
        rebaseWhenBranchingFromDefaultBranch = try container.decode(Bool.self, forKey: .rebaseWhenBranchingFromDefaultBranch)
        pruneWhenDeletingBranches = try container.decodeIfPresent(Bool.self, forKey: .pruneWhenDeletingBranches) ?? false
    }
}

extension GitConfig {
    static var defaultConfig: GitConfig {
        return .init(defaultBranch: "main",
                    branchPrefixList: [],
                    rebaseWhenBranchingFromDefaultBranch: true,
                    pruneWhenDeletingBranches: false)
    }
}
