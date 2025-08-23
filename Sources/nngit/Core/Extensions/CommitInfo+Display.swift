//
//  CommitInfo+Display.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit

extension CommitInfo {
    var coloredMessage: String {
        let authorName = wasAuthoredByCurrentUser ? author.green : author.lightRed
        
        return "\(hash.yellow) | (\(authorName), \(date) - \(message.bold)"
    }
}