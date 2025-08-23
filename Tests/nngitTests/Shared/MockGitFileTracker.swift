//
//  MockGitFileTracker.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/23/25.
//

@testable import nngit

final class MockGitFileTracker: GitFileTracker {
    private let unwantedFiles: [String]
    private let filesToFailStopping: [String]
    
    private(set) var stoppedTrackingFiles: [String] = []
    private(set) var loadUnwantedFilesCallCount = 0
    private(set) var stopTrackingFileCallCount = 0
    private(set) var lastGitignoreContent: String?
    
    init(unwantedFiles: [String] = [], filesToFailStopping: [String] = []) {
        self.unwantedFiles = unwantedFiles
        self.filesToFailStopping = filesToFailStopping
    }
    
    func loadUnwantedFiles(gitignore: String) -> [String] {
        loadUnwantedFilesCallCount += 1
        lastGitignoreContent = gitignore
        return unwantedFiles
    }
    
    func stopTrackingFile(file: String) throws {
        stopTrackingFileCallCount += 1
        
        if filesToFailStopping.contains(file) {
            throw TestError.stopTrackingFailed
        }
        
        stoppedTrackingFiles.append(file)
    }
    
    func containsUntrackedFiles() throws -> Bool {
        return true
    }
    
    enum TestError: Error {
        case stopTrackingFailed
        
        var localizedDescription: String {
            switch self {
            case .stopTrackingFailed:
                return "Failed to stop tracking file"
            }
        }
    }
}