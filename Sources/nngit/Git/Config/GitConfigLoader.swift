import SwiftPicker

protocol GitConfigLoader {
    func save(_ config: GitConfig) throws
    func loadConfig(picker: CommandLinePicker) throws -> GitConfig
}
