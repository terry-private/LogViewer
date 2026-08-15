import LogViewerCore
import Logging

/// SwiftLogのログをLogViewerの保存機能へ渡す接続部品。
public struct LogViewerLogHandler: LogHandler {
    /// SwiftLogの`source`を保存する付加情報キー。
    public static let sourceMetadataKey = "swift-log.source"
    /// SwiftLogへ渡されたErrorの説明を保存する付加情報キー。
    public static let errorMessageMetadataKey = "error.message"
    /// SwiftLogへ渡されたErrorの型名を保存する付加情報キー。
    public static let errorTypeMetadataKey = "error.type"

    private let label: String
    private let store: any LogStore

    /// この水準以上のログを受け付ける。
    public var logLevel: Logging.Logger.Level
    /// Logger単位で付与する付加情報。
    public var metadata: Logging.Logger.Metadata
    /// Task Localなどから付加情報を供給する機能。
    public var metadataProvider: Logging.Logger.MetadataProvider?

    /// SwiftLogの識別子とLogViewerの保存先を指定する。
    public init(
        label: String,
        store: any LogStore,
        logLevel: Logging.Logger.Level = .info,
        metadata: Logging.Logger.Metadata = [:],
        metadataProvider: Logging.Logger.MetadataProvider? = nil
    ) {
        self.label = label
        self.store = store
        self.logLevel = logLevel
        self.metadata = metadata
        self.metadataProvider = metadataProvider
    }

    /// 指定したキーのLogger単位の付加情報を読み書きする。
    public subscript(
        metadataKey metadataKey: String
    ) -> Logging.Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    /// SwiftLogの出来事を1件の`LogEntry`へ変換して保存する。
    public func log(event: LogEvent) {
        var effectiveMetadata = metadata
        if let providedMetadata = metadataProvider?.get() {
            effectiveMetadata.merge(
                providedMetadata,
                uniquingKeysWith: { _, provided in provided }
            )
        }
        if let explicitMetadata = event.metadata {
            effectiveMetadata.merge(
                explicitMetadata,
                uniquingKeysWith: { _, explicit in explicit }
            )
        }
        if let error = event.error {
            effectiveMetadata[Self.errorMessageMetadataKey] = "\(error)"
            effectiveMetadata[Self.errorTypeMetadataKey] = .string(
                String(reflecting: type(of: error))
            )
        }
        effectiveMetadata[Self.sourceMetadataKey] = .string(event.source)

        store.add(LogEntry(
            level: event.level.logViewerLevel,
            message: event.message.description,
            source: SourceLocation(
                fileID: event.file,
                function: event.function,
                line: event.line
            ),
            category: label.isEmpty ? nil : label,
            metadata: effectiveMetadata.mapValues(Self.metadataString)
        ))
    }

    private static func metadataString(
        _ value: Logging.Logger.Metadata.Value
    ) -> String {
        switch value {
        case let .string(value):
            value
        case let .stringConvertible(value):
            value.description
        case let .array(values):
            "[" + values.map {
                String(reflecting: metadataString($0))
            }.joined(separator: ",") + "]"
        case let .dictionary(values):
            "{" + values.sorted { $0.key < $1.key }.map {
                String(reflecting: $0.key)
                    + ":"
                    + String(reflecting: metadataString($0.value))
            }.joined(separator: ",") + "}"
        }
    }
}

private extension Logging.Logger.Level {
    var logViewerLevel: LogViewerCore.LogLevel {
        switch self {
        case .trace: .trace
        case .debug: .debug
        case .info: .info
        case .notice: .notice
        case .warning: .warning
        case .error: .error
        case .critical: .critical
        }
    }
}
