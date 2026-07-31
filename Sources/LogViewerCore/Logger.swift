/// 既存の簡潔な記録APIと、差し替え可能な保存機能をつなぐ窓口。
public final class Logger: Sendable {
    /// 互換性のために提供する共有ロガー。
    public static let shared = Logger()

    /// このロガーが使用する保存機能。
    public let store: any LogStore

    /// 指定した保存機能を使うロガーを作成する。
    public init(store: any LogStore = InMemoryLogStore()) {
        self.store = store
    }

    /// 公開ログモデルを保存する。
    public func add(_ entry: LogEntry) {
        store.add(entry)
    }

    /// 新しいログを保存するかどうかを設定する。
    public func setRecordingEnabled(_ isEnabled: Bool) {
        store.setRecordingEnabled(isEnabled)
    }

    /// 現在保存されているログをすべて削除する。
    public func deleteAll() {
        store.deleteAll()
    }
}

public extension Logger {
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
