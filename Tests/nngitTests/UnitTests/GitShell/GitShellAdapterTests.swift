import Testing
@testable import nngit

struct GitShellAdapterTests {
    @Test("throws error when git command fails")
    func throwsOnCommandFailure() throws {
        let shell = GitShellAdapter()
        
        #expect {
            try shell.runWithOutput("git invalidcommand")
        } throws: { error in
            guard let commandError = error as? GitShellError else {
                return false
            }
                
            switch commandError {
            case .commandFailed(let code, let command, _):
                return code != 0 && command.contains("git invalidcommand")
            default:
                return false
            }
        }
    }
}
