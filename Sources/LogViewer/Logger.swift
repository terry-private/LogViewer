import Foundation

@MainActor
@Observable
public final class Logger {
    internal var active: Bool = true
    internal var logs: [Log] = []
    internal var fileTagToLogs: [String: [Log]] = [:]
    internal var functionTagToLogs: [String: [Log]] = [:]
    internal init() {}

    internal func fileLogs(for name: String) -> [Log] {
        fileTagToLogs[name] ?? []
    }
    internal func functionLogs(for functionTag: String) -> [Log] {
        functionTagToLogs[functionTag] ?? []
    }
    internal func add(_ log: Log) {
        guard active else { return }
        logs.append(log)
        fileTagToLogs[log.fileID, default: []].append(log)
        functionTagToLogs[log.fileID + "\n> " + log.function, default: []].append(log)
    }
    internal func deleteAll() {
        logs.removeAll()
        fileTagToLogs.removeAll()
        functionTagToLogs.removeAll()
    }
}

public extension Logger {
    static let shared: Logger = .init()

    func add(_ message: String, tags: Tag..., fileID: String = #fileID, function: String = #function) {
        let log = Log(message: message, tags: Set(tags), fileID: fileID, function: function)
        add(log)
    }
}
