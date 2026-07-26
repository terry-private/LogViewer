/// ログの重要度。定義順に重大度が高くなる。
public enum LogLevel: Int, Codable, Sendable, Hashable, CaseIterable {
    /// 最も詳細な追跡情報。
    case trace = 0
    /// デバッグ時に使う情報。
    case debug = 1
    /// 通常の動作情報。
    case info = 2
    /// 注目すべき正常動作。
    case notice = 3
    /// 回復可能な問題や注意。
    case warning = 4
    /// 処理の失敗。
    case error = 5
    /// 継続動作へ大きく影響する重大な失敗。
    case critical = 6
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
