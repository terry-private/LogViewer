/// ある時点におけるログ保存機能の読み取り専用状態。
public struct LogStoreSnapshot: Sendable, Equatable {
    /// 保存済みログ。保存された順序を維持する。
    public let entries: [LogEntry]

    /// 新しいログを保存する状態かどうか。
    public let isRecordingEnabled: Bool

    /// 保存済みログと記録状態からスナップショットを作成する。
    public init(
        entries: [LogEntry],
        isRecordingEnabled: Bool
    ) {
        self.entries = entries
        self.isRecordingEnabled = isRecordingEnabled
    }
}
