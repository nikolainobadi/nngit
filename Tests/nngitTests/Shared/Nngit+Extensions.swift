import Foundation
import ArgumentParser
@testable import nngit

extension Nngit {
    /// Runs the command with the provided arguments and returns any printed output.
    @discardableResult
    static func testRun(context: NnGitContext? = nil, args: [String]? = []) throws -> String {
        self.context = context ?? MockContext()
        return try captureOutput(args: args)
    }
}

private extension Nngit {
    /// Captures stdout from invoking the command so it can be asserted in tests.
    static func captureOutput(args: [String]?) throws -> String {
        let pipe = Pipe()
        let readHandle = pipe.fileHandleForReading
        let writeHandle = pipe.fileHandleForWriting

        let originalStdout = dup(STDOUT_FILENO)
        dup2(writeHandle.fileDescriptor, STDOUT_FILENO)

        do {
            var command = try Self.parseAsRoot(args)
            try command.run()
        } catch {
            // Restore stdout before rethrowing
            fflush(stdout)
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            writeHandle.closeFile()
            readHandle.closeFile()
            throw error
        }

        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        writeHandle.closeFile()

        let data = readHandle.readDataToEndOfFile()
        readHandle.closeFile()

        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
