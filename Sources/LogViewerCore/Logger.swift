import Foundation
import Observation
import OrderedCollections

@MainActor
@Observable
public final class Logger {
    package var active: Bool = true
    package var logs: [Log] = []
    package var tags: OrderedSet<Tag> = []
    package var fileTagToLogs: [String: [Log]] = [:]
    package var functionTagToLogs: [String: [Log]] = [:]
    package init() {}

    package func fileLogs(for name: String) -> [Log] {
        fileTagToLogs[name] ?? []
    }
    package func functionLogs(for functionTag: String) -> [Log] {
        functionTagToLogs[functionTag] ?? []
    }
    package func add(_ log: Log) {
        guard active else { return }
        logs.append(log)
        tags.formUnion(log.tags)
        fileTagToLogs[log.fileID, default: []].append(log)
        functionTagToLogs[log.fileID + "\n> " + log.function, default: []].append(log)
    }
    package func deleteAll() {
        logs.removeAll()
        tags.removeAll()
        fileTagToLogs.removeAll()
        functionTagToLogs.removeAll()
    }
}

public extension Logger {
    static let shared: Logger = .init()

    func add(_ message: String, tags: Tag..., fileID: String = #fileID, function: String = #function) {
        let log = Log(message: message, tags: OrderedSet(tags), fileID: fileID, function: function)
        add(log)
    }

    func add(_ message: String, tags: [Tag], fileID: String = #fileID, function: String = #function) {
        let log = Log(message: message, tags: OrderedSet(tags), fileID: fileID, function: function)
        add(log)
    }
}
