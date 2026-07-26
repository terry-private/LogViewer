import Foundation
import Observation
import OrderedCollections

@MainActor
@Observable
public final class Logger {
    package var active: Bool = true
    package var logs: [LogEntry] = []
    package var tags: OrderedSet<Tag> = []
    package var fileTagToLogs: [String: [LogEntry]] = [:]
    package var functionTagToLogs: [String: [LogEntry]] = [:]
    package init() {}

    package func fileLogs(for name: String) -> [LogEntry] {
        fileTagToLogs[name] ?? []
    }
    package func functionLogs(for functionTag: String) -> [LogEntry] {
        functionTagToLogs[functionTag] ?? []
    }
    /// 公開ログモデルを保存する。
    public func add(_ entry: LogEntry) {
        guard active else { return }
        logs.append(entry)
        tags.formUnion(entry.tags)
        fileTagToLogs[entry.source.fileID, default: []].append(entry)
        let functionKey = entry.source.fileID + "\n> " + entry.source.function
        functionTagToLogs[functionKey, default: []].append(entry)
    }
    package func deleteAll() {
        logs.removeAll()
        tags.removeAll()
        fileTagToLogs.removeAll()
        functionTagToLogs.removeAll()
    }
}

public extension Logger {
    /// 互換性のために提供する共有ロガー。
    static let shared: Logger = .init()

    /// 文字列と可変長タグからログを作成して保存する互換API。
    func add(
        _ message: String,
        tags: Tag...,
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        add(
            LogEntry(
                message: message,
                source: SourceLocation(
                    fileID: fileID,
                    function: function,
                    line: line
                ),
                tags: tags
            )
        )
    }

    /// 文字列とタグ配列からログを作成して保存する互換API。
    func add(
        _ message: String,
        tags: [Tag],
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        add(
            LogEntry(
                message: message,
                source: SourceLocation(
                    fileID: fileID,
                    function: function,
                    line: line
                ),
                tags: tags
            )
        )
    }
}
