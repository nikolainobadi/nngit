//import Testing
//import GitShellKit
//@testable import nngit
//
//@MainActor
//struct DiscardCommandTests {
//    @Test("clears staged and unstaged files")
//    func clearsAllChanges() throws {
//        let localGitCheckCommand = makeGitCommand(.localGitCheck, path: nil)
//        let localChangesCommand = makeGitCommand(.getLocalChanges, path: nil)
//        let responses = [
//            localGitCheckCommand: "true",
//            localChangesCommand: "M file.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//
//        try runCommand(context)
//
//        #expect(shell.commands.contains(localChangesCommand))
//        #expect(shell.commands.contains(localGitCheckCommand))
//        #expect(shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
//        #expect(shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to discard the changes you made in this branch? You cannot undo this action."))
//    }
//    
//    @Test("clears only staged files")
//    func clearsOnlyStagedFiles() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context, discardScope: .staged)
//        
//        #expect(shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
//        #expect(!shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
//    }
//
//    @Test("clears only unstaged files")
//    func clearsOnlyUnstagedFiles() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context, discardScope: .unstaged)
//        
//        #expect(shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
//        #expect(!shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
//    }
//
//    @Test("prints no changes detected when working directory is clean")
//    func printsNoChangesDetected() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommand(context)
//
//        #expect(!shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
//        #expect(!shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
//    }
//    
//    @Test("shows file selection when --files flag is used")
//    func showsFileSelectionWhenFilesFlag() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file1.swift\nA  file2.swift\n?? file3.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommandWithFiles(context)
//        
//        #expect(shell.commands.contains(makeGitCommand(.getLocalChanges, path: nil)))
//        #expect(!shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
//        #expect(!shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
//    }
//    
//    @Test("discards selected files when files are chosen")
//    func discardsSelectedFilesWhenChosen() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file1.swift\nA  file2.swift",
//            "git checkout -- \"file1.swift\"": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        // Mock that user selects files - MockPicker returns [items[0]] for this response
//        picker.selectionResponses["Select files to discard changes from:"] = 0
//        // Mock permission response for confirmation
//        picker.permissionResponses["Are you sure you want to discard changes in 1 selected file(s)? You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommandWithFiles(context)
//        
//        // Check that the git commands were executed for the first file (which has unstaged changes)
//        #expect(shell.commands.contains("git checkout -- \"file1.swift\""))
//    }
//    
//    @Test("filters files by scope when using file selection")
//    func filtersFilesByScopeWhenUsingFileSelection() throws {
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.getLocalChanges, path: nil): " M file1.swift\nA  file2.swift\n?? file3.swift"
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//        
//        try runCommandWithFiles(context, discardScope: .staged)
//        
//        #expect(shell.commands.contains(makeGitCommand(.getLocalChanges, path: nil)))
//        // Should only show staged files (A file2.swift) in picker
//    }
//}
//
//
//// MARK: - Helper Methods
//private extension DiscardCommandTests {
//    func runCommand(_ testFactory: NnGitContext, discardScope: DiscardScope = .both) throws {
//        var args = ["discard"]
//        
//        switch discardScope {
//        case .staged:
//            args = args + ["-s", "staged"]
//        case .unstaged:
//            args = args + ["-s", "unstaged"]
//        case .both:
//            break
//        }
//        
//        try Nngit.testRun(context: testFactory, args: args)
//    }
//    
//    func runCommandWithFiles(_ testFactory: NnGitContext, discardScope: DiscardScope = .both) throws {
//        var args = ["discard", "--files"]
//        
//        switch discardScope {
//        case .staged:
//            args = args + ["-s", "staged"]
//        case .unstaged:
//            args = args + ["-s", "unstaged"]
//        case .both:
//            break
//        }
//        
//        try Nngit.testRun(context: testFactory, args: args)
//    }
//}
