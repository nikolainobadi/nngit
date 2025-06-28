//
//  CommitInfo.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

/// Lightweight model describing a single commit returned from git log.
struct CommitInfo {
    let hash: String
    let message: String
    let author: String
    let date: String
    let wasAuthoredByCurrentUser: Bool
}
