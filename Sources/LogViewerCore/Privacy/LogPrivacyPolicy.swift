import Foundation

/// ログ内の文字列へ適用する秘匿化規則。
public struct LogRedactionRule: Sendable, Hashable {
    private let pattern: String
    /// 一致箇所を置き換える文字列。
    public let replacement: String
    private let replacementTemplate: String
    private let expression: SendableRegularExpression

    /// 指定した文字列と完全に同じ部分を置き換える規則を作成する。
    public init(
        matching literal: String,
        replacement: String = "<private>"
    ) throws {
        guard !literal.isEmpty else {
            throw LogRedactionRuleError.emptyLiteral
        }
        let pattern = NSRegularExpression.escapedPattern(for: literal)
        expression = SendableRegularExpression(
            try NSRegularExpression(pattern: pattern)
        )
        self.pattern = pattern
        self.replacement = replacement
        replacementTemplate = NSRegularExpression.escapedTemplate(
            for: replacement
        )
    }

    /// 一般的なメールアドレスを伏せ字にする規則。
    public static let emailAddress = LogRedactionRule(
        validatedPattern: #"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#
    )

    /// `Bearer`認証値を伏せ字にする規則。
    public static let bearerToken = LogRedactionRule(
        validatedPattern: #"(?i)\bBearer\s+[A-Z0-9._~+/=-]+"#
    )

    private init(
        validatedPattern pattern: String,
        replacement: String = "<private>"
    ) {
        self.pattern = pattern
        self.replacement = replacement
        replacementTemplate = NSRegularExpression.escapedTemplate(
            for: replacement
        )
        expression = SendableRegularExpression(
            try! NSRegularExpression(pattern: pattern)
        )
    }

    fileprivate func redact(_ value: String) -> String {
        let range = NSRange(value.startIndex..., in: value)
        return expression.value.stringByReplacingMatches(
            in: value,
            range: range,
            withTemplate: replacementTemplate
        )
    }

    public static func == (
        lhs: LogRedactionRule,
        rhs: LogRedactionRule
    ) -> Bool {
        lhs.pattern == rhs.pattern && lhs.replacement == rhs.replacement
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
        hasher.combine(replacement)
    }
}

private final class SendableRegularExpression: @unchecked Sendable {
    let value: NSRegularExpression

    init(_ value: NSRegularExpression) {
        self.value = value
    }
}

/// ログの保存、表示、書き出しへ共通して適用する秘匿化方針。
public struct LogPrivacyPolicy: Sendable, Hashable {
    /// 文字列へ順番に適用する秘匿化規則。
    public let rules: [LogRedactionRule]
    /// 値を伏せ字へ置き換える付加情報キー。
    public let redactedMetadataKeys: Set<String>
    /// キーと値をログから取り除く付加情報キー。
    public let removedMetadataKeys: Set<String>
    /// 付加情報値を置き換える文字列。
    public let metadataReplacement: String

    /// 秘匿化規則と付加情報の公開範囲を指定する。
    public init(
        rules: [LogRedactionRule] = [],
        redactedMetadataKeys: Set<String> = [],
        removedMetadataKeys: Set<String> = [],
        metadataReplacement: String = "<private>"
    ) {
        self.rules = rules
        self.redactedMetadataKeys = Set(
            redactedMetadataKeys.map { $0.lowercased() }
        )
        self.removedMetadataKeys = Set(
            removedMetadataKeys.map { $0.lowercased() }
        )
        self.metadataReplacement = metadataReplacement
    }

    /// ログを変更しない方針。
    public static let none = LogPrivacyPolicy()

    /// メールアドレス、Bearer値、一般的な秘密の付加情報を伏せ字にする方針。
    public static let standard = LogPrivacyPolicy(
        rules: [.emailAddress, .bearerToken],
        redactedMetadataKeys: [
            "authorization",
            "token",
            "access_token",
            "refresh_token",
            "password",
            "email",
        ]
    )

    /// この方針を1件のログへ適用した、新しい値を返す。
    public func redacting(_ entry: LogEntry) -> LogEntry {
        guard self != .none else { return entry }
        var metadata: [String: String] = [:]
        metadata.reserveCapacity(entry.metadata.count)
        for (key, value) in entry.metadata.sorted(by: { $0.key < $1.key }) {
            let normalizedKey = key.lowercased()
            guard !removedMetadataKeys.contains(normalizedKey) else {
                continue
            }
            let protectedKey = uniqueMetadataKey(
                basedOn: redact(key),
                existing: metadata
            )
            metadata[protectedKey] = redactedMetadataKeys.contains(normalizedKey)
                ? metadataReplacement
                : redact(value)
        }

        return LogEntry(
            id: entry.id,
            level: entry.level,
            message: redact(entry.message),
            source: SourceLocation(
                fileID: redact(entry.source.fileID),
                function: redact(entry.source.function),
                line: entry.source.line
            ),
            category: entry.category.map(redact),
            tags: entry.tags.map { Tag(rawValue: redact($0.rawValue)) },
            metadata: metadata,
            timestamp: entry.timestamp
        )
    }

    /// この方針を複数のログへ適用する。
    public func redacting(_ entries: [LogEntry]) -> [LogEntry] {
        guard self != .none else { return entries }
        return entries.map(redacting)
    }

    private func redact(_ value: String) -> String {
        guard !rules.isEmpty else { return value }
        return rules.reduce(value) { value, rule in
            rule.redact(value)
        }
    }

    private func uniqueMetadataKey(
        basedOn base: String,
        existing metadata: [String: String]
    ) -> String {
        guard metadata[base] == nil else {
            var suffix = 2
            while metadata["\(base)#\(suffix)"] != nil {
                suffix += 1
            }
            return "\(base)#\(suffix)"
        }
        return base
    }
}

/// 独自の秘匿化規則を作成できない理由。
public enum LogRedactionRuleError: Error, Sendable {
    /// 一致対象の文字列が空である。
    case emptyLiteral
}
