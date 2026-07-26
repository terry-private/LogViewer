/// ログを生成したソースコード上の位置。
public struct SourceLocation: Codable, Sendable, Hashable {
    /// モジュール名を含むソースファイルの識別子。
    public let fileID: String
    /// ログを生成した関数名。
    public let function: String
    /// ログを生成した行番号。
    public let line: UInt

    /// ファイル、関数、行番号から発生元を作成する。
    public init(
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.fileID = fileID
        self.function = function
        self.line = line
    }
}
