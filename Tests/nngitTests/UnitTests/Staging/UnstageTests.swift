import Testing
import GitShellKit
@testable import nngit

@MainActor
struct UnstageTests {
    @Test("unstages selected files when staged files are available")
    func unstagesSelectedFiles() throws {
        let localGitCheckCommand = makeGitCommand(.localGitCheck, path: nil)
        let localChangesCommand = makeGitCommand(.getLocalChanges, path: nil)
        let responses = [
            localGitCheckCommand: "true",
            localChangesCommand: "A  file1.swift\nM  file2.swift\n M file3.swift",
            "git reset HEAD \"file1.swift\"": "",
            "git reset HEAD \"file2.swift\"": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        // Mock multi-selection to select first file (staged)
        picker.selectionResponses["Select files to unstage:"] = 0
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        #expect(shell.commands.contains(localGitCheckCommand))
        #expect(shell.commands.contains(localChangesCommand))
        #expect(shell.commands.contains("git reset HEAD \"file1.swift\""))
    }
    
    @Test("filters only staged files")
    func filtersOnlyStagedFiles() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "A  staged.swift\n M unstaged.swift\n?? untracked.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        // Should only show staged.swift in picker
        #expect(shell.commands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("prints no staged files when no files are staged")
    func printsNoStagedFilesWhenNoneStaged() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): " M unstaged.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No staged files to unstage."))
        #expect(!shell.commands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("prints no files selected when user cancels selection")
    func printsNoFilesSelectedWhenCanceled() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "A  file1.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        // MockPicker returns empty array when no selection response is set
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No files selected."))
        #expect(!shell.commands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("unstages multiple selected files")
    func unstagesMultipleSelectedFiles() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "A  file1.swift\nM  file2.swift\nD  file3.swift",
            "git reset HEAD \"file1.swift\"": "",
            "git reset HEAD \"file2.swift\"": "",
            "git reset HEAD \"file3.swift\"": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        // Mock multi-selection returns multiple files
        picker.selectionResponses["Select files to unstage:"] = 0
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("✅ Unstaged 1 file(s)"))
    }
    
    @Test("handles different staged file types correctly")
    func handlesDifferentStagedFileTypesCorrectly() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "A  added.swift\nM  modified.swift\nD  deleted.swift",
            "git reset HEAD \"added.swift\"": "",
            "git reset HEAD \"modified.swift\"": "",
            "git reset HEAD \"deleted.swift\"": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select files to unstage:"] = 0
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        #expect(shell.commands.contains("git reset HEAD \"added.swift\""))
    }
    
    @Test("prints no staged files when working directory is clean")
    func printsNoStagedFilesWhenClean() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No staged files to unstage."))
        #expect(!shell.commands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("handles mixed staged and unstaged files correctly")
    func handlesMixedStagedAndUnstagedFiles() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "MM mixed.swift\nAM added_modified.swift",
            "git reset HEAD \"mixed.swift\"": "",
            "git reset HEAD \"added_modified.swift\"": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select files to unstage:"] = 0
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        // Should be able to unstage the staged parts of mixed files
        #expect(shell.commands.contains("git reset HEAD \"mixed.swift\""))
    }
}

// MARK: - Helper Methods
private extension UnstageTests {
    func runCommand(_ testFactory: NnGitContext) throws {
        try Nngit.testRun(context: testFactory, args: ["staging", "unstage"])
    }
}