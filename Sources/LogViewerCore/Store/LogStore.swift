/// ログの保存、制御、変更通知を提供する抽象化。
public protocol LogStore: Sendable {
    /// 現在の保存状態を取得する。
    func snapshot() -> LogStoreSnapshot

    /// 現在値と以後の変更を受け取るストリームを作成する。
    func updates() -> AsyncStream<LogStoreSnapshot>

    /// ログを保存する。一時停止中のログは破棄する。
    func add(_ entry: LogEntry)

    /// 新しいログを保存するかどうかを設定する。
    func setRecordingEnabled(_ isEnabled: Bool)

    /// 呼び出し時点までに保存されたログを削除する。
    func deleteAll()
}
