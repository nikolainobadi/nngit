//
//  BehaviorOptions.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

extension GitConfig {
    struct BehaviorOptions: Codable {
        var rebaseWhenBranchingFromDefault: Bool
        var pruneWhenDeleting: Bool
        
        init(rebaseWhenBranchingFromDefault: Bool = true, pruneWhenDeleting: Bool = false) {
            self.rebaseWhenBranchingFromDefault = rebaseWhenBranchingFromDefault
            self.pruneWhenDeleting = pruneWhenDeleting
        }
    }
}
