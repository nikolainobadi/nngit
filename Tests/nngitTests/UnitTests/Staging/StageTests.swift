//import Testing
//import GitShellKit
//@testable import nngit
//
//@MainActor
//struct StageTests {
//    @Test("stages selected files when files are available")
//    func stagesSelectedFiles() throws {
//        let localGitCheckCommand = makeGitCommand(.localGitCheck, path: nil)
//        let localChangesCommand = makeGitCommand(.getLocalChanges, path: nil)
//        let responses = [
//            localGitCheckCommand: "true",
//            localChangesCommand: " M file1.swift\n?? file2.swift\n D file3.swift",
//            "git add \"file1.swift\"": "",
//            "git add \"file2.swift\"": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        // Mock multi-selection to select first two files (unstaged and untracked)
//        picker.selectionResponses["Select files to stage:"] = 0
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context)
//        
//        #expect(shell.commands.contains(localGitCheckCommand))
//        #expect(shell.commands.contains(localChangesCommand))
//        #expect(shell.commands.contains("git add \"file1.swift\""))
//    }
//    
//    @Test("filters only unstaged and untracked files")
//    func filtersOnlyUnstagedAndUntrackedFiles() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): "A  staged.swift\n M unstaged.swift\n?? untracked.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context)
//        
//        // Should only show unstaged.swift and untracked.swift in picker
//        #expect(shell.commands.contains(makeGitCommand(.getLocalChanges, path: nil)))
//    }
//    
//    @Test("prints no files available when all files are staged")
//    func printsNoFilesAvailableWhenAllStaged() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): "A  staged1.swift\nM  staged2.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        let output = try Nngit.testRun(context: context, args: ["staging", "stage"])
//        
//        #expect(output.contains("No files available to stage."))
//        #expect(!shell.commands.contains { $0.starts(with: "git add") })
//    }
//    
//    @Test("prints no files selected when user cancels selection")
//    func printsNoFilesSelectedWhenCanceled() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file1.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        // MockPicker returns empty array when no selection response is set
//        let context = MockContext(picker: picker, shell: shell)
//        
//        let output = try Nngit.testRun(context: context, args: ["staging", "stage"])
//        
//        #expect(output.contains("No files selected."))
//        #expect(!shell.commands.contains { $0.starts(with: "git add") })
//    }
//    
//    @Test("stages multiple selected files")
//    func stagesMultipleSelectedFiles() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file1.swift\n?? file2.swift\n D file3.swift",
//            "git add \"file1.swift\"": "",
//            "git add \"file2.swift\"": "",
//            "git add \"file3.swift\"": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        // Mock multi-selection returns multiple files
//        picker.selectionResponses["Select files to stage:"] = 0
//        let context = MockContext(picker: picker, shell: shell)
//        
//        let output = try Nngit.testRun(context: context, args: ["staging", "stage"])
//        
//        #expect(output.contains("✅ Staged 1 file(s)"))
//    }
//    
//    @Test("handles untracked files correctly")
//    func handlesUntrackedFilesCorrectly() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): "?? newfile.swift",
//            "git add \"newfile.swift\"": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select files to stage:"] = 0
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context)
//        
//        #expect(shell.commands.contains("git add \"newfile.swift\""))
//    }
//    
//    @Test("prints no files available when working directory is clean")
//    func printsNoFilesWhenClean() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        let output = try Nngit.testRun(context: context, args: ["staging", "stage"])
//        
//        #expect(output.contains("No files available to stage."))
//        #expect(!shell.commands.contains { $0.starts(with: "git add") })
//    }
//}
//
//// MARK: - Helper Methods
//private extension StageTests {
//    func runCommand(_ testFactory: NnGitContext) throws {
//        try Nngit.testRun(context: testFactory, args: ["staging", "stage"])
//    }
//}
