import Foundation

/// ログを書き出す形式。
public enum LogExportFormat: Sendable, Hashable {
    /// 人が読みやすい1行1ログのテキスト。
    case plainText
    /// `LogEntry`配列を表すJSON。
    case json
}

/// ログへ秘匿化を適用してテキストまたはJSONへ変換する機能。
public struct LogExporter: Sendable {
    /// 書き出し直前に適用する秘匿化方針。
    public let privacyPolicy: LogPrivacyPolicy

    /// 書き出し用の秘匿化方針を指定する。
    public init(privacyPolicy: LogPrivacyPolicy = .none) {
        self.privacyPolicy = privacyPolicy
    }

    /// 指定したログだけを選択形式のデータへ変換する。
    public func data(
        from entries: [LogEntry],
        format: LogExportFormat
    ) throws -> Data {
        let entries = privacyPolicy.redacting(entries)
        switch format {
        case .plainText:
            return Data(text(from: entries).utf8)
        case .json:
            let encoder = JSONEncoder()
            let timestampStyle = Self.timestampStyle()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                try container.encode(timestampStyle.format(date))
            }
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys,
                .withoutEscapingSlashes,
            ]
            return try encoder.encode(entries)
        }
    }

    /// 指定したログをUTF-8文字列へ変換する。
    public func string(
        from entries: [LogEntry],
        format: LogExportFormat
    ) throws -> String {
        let data = try data(from: entries, format: format)
        guard let string = String(data: data, encoding: .utf8) else {
            throw LogExportError.invalidUTF8
        }
        return string
    }

    private func text(from entries: [LogEntry]) -> String {
        let timestampStyle = Self.timestampStyle()
        let textEncoder = JSONEncoder()
        textEncoder.outputFormatting = [.withoutEscapingSlashes]
        return entries.map { entry in
            let tags = entry.tags
                .map { Self.quoted($0.rawValue, encoder: textEncoder) }
                .joined(separator: ",")
            let metadata = entry.metadata
                .sorted { $0.key < $1.key }
                .map {
                    "\(Self.quoted($0.key, encoder: textEncoder)):"
                        + Self.quoted($0.value, encoder: textEncoder)
                }
                .joined(separator: ",")
            let details = [
                entry.category.map {
                    "category=\(Self.quoted($0, encoder: textEncoder))"
                },
                tags.isEmpty ? nil : "tags=[\(tags)]",
                metadata.isEmpty ? nil : "metadata={\(metadata)}",
            ].compactMap { $0 }.joined(separator: " ")
            let suffix = details.isEmpty ? "" : " \(details)"
            let message = Self.quoted(entry.message, encoder: textEncoder)
            let fileID = Self.quoted(entry.source.fileID, encoder: textEncoder)
            let function = Self.quoted(
                entry.source.function,
                encoder: textEncoder
            )
            return "\(timestampStyle.format(entry.timestamp)) "
                + "level=\(entry.level.exportName) "
                + "message=\(message) "
                + "file=\(fileID) "
                + "line=\(entry.source.line) "
                + "function=\(function)\(suffix)"
        }.joined(separator: "\n")
    }

    private static func quoted(
        _ value: String,
        encoder: JSONEncoder
    ) -> String {
        guard
            let data = try? encoder.encode(value),
            let quoted = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return quoted
    }

    private static func timestampStyle() -> Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    }
}

/// ログ書き出し時の変換エラー。
public enum LogExportError: Error, Sendable {
    /// 生成されたデータをUTF-8文字列へ変換できない。
    case invalidUTF8
}

private extension LogLevel {
    var exportName: String {
        switch self {
        case .trace: "TRACE"
        case .debug: "DEBUG"
        case .info: "INFO"
        case .notice: "NOTICE"
        case .warning: "WARNING"
        case .error: "ERROR"
        case .critical: "CRITICAL"
        }
    }
}
