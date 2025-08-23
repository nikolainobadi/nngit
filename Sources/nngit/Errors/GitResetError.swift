//
//  GitResetError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

enum GitResetError: Error {
    case invalidCount
}

extension GitResetError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidCount:
            return "Number of commits to reset must be greater than 0"
        }
    }
}
