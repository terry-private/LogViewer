import Foundation
import OrderedCollections

/// LogViewerが保存・表示する1件のログ。
public struct LogEntry: Codable, Sendable, Hashable, Identifiable {
    /// ログを一意に識別する値。
    public let id: UUID
    /// ログの重要度。
    public let level: LogLevel
    /// 利用者へ表示する本文。
    public let message: String
    /// ログを生成したソースコード上の位置。
    public let source: SourceLocation
    /// ログを分類する任意の名前。
    public let category: String?
    /// 絞り込みに使うタグ。重複は最初の出現を残して除去される。
    public let tags: [Tag]
    /// ログへ付加する文字列のキーと値。
    public let metadata: [String: String]
    /// ログが生成された日時。
    public let timestamp: Date

    /// すべての公開情報を指定してログを作成する。
    public init(
        id: UUID = UUID(),
        level: LogLevel = .info,
        message: String,
        source: SourceLocation,
        category: String? = nil,
        tags: [Tag] = [],
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.level = level
        self.message = message
        self.source = source
        self.category = category
        self.tags = Array(OrderedSet(tags))
        self.metadata = metadata
        self.timestamp = timestamp
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            level: try container.decode(LogLevel.self, forKey: .level),
            message: try container.decode(String.self, forKey: .message),
            source: try container.decode(
                SourceLocation.self,
                forKey: .source
            ),
            category: try container.decodeIfPresent(
                String.self,
                forKey: .category
            ),
            tags: try container.decode([Tag].self, forKey: .tags),
            metadata: try container.decode(
                [String: String].self,
                forKey: .metadata
            ),
            timestamp: try container.decode(Date.self, forKey: .timestamp)
        )
    }
}

extension LogEntry: Comparable {
    public static func < (lhs: LogEntry, rhs: LogEntry) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp < rhs.timestamp
        }
        if lhs.id != rhs.id {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        if lhs.level != rhs.level {
            return lhs.level < rhs.level
        }
        if lhs.message != rhs.message {
            return lhs.message < rhs.message
        }
        if lhs.source.fileID != rhs.source.fileID {
            return lhs.source.fileID < rhs.source.fileID
        }
        if lhs.source.function != rhs.source.function {
            return lhs.source.function < rhs.source.function
        }
        if lhs.source.line != rhs.source.line {
            return lhs.source.line < rhs.source.line
        }
        if lhs.category != rhs.category {
            switch (lhs.category, rhs.category) {
            case (nil, .some):
                return true
            case (.some, nil):
                return false
            case let (.some(lhsCategory), .some(rhsCategory)):
                return lhsCategory < rhsCategory
            case (nil, nil):
                break
            }
        }
        if lhs.tags != rhs.tags {
            return lhs.tags.lexicographicallyPrecedes(rhs.tags)
        }

        let lhsMetadata = lhs.metadata.sorted { $0.key < $1.key }
        let rhsMetadata = rhs.metadata.sorted { $0.key < $1.key }
        for (lhsPair, rhsPair) in zip(lhsMetadata, rhsMetadata) {
            if lhsPair.key != rhsPair.key {
                return lhsPair.key < rhsPair.key
            }
            if lhsPair.value != rhsPair.value {
                return lhsPair.value < rhsPair.value
            }
        }
        return lhsMetadata.count < rhsMetadata.count
    }
}

package extension [LogEntry] {
    func filter(by tags: Set<Tag>) -> [LogEntry] {
        if tags.isEmpty {
            lazy.filter { entry in
                entry.tags.isEmpty
            }
        } else {
            lazy.filter { entry in
                !tags.isDisjoint(with: entry.tags)
            }
        }
    }

    func filter(by logFilter: LogFilter) -> [LogEntry] {
        switch logFilter {
        case .all:
            self
        case .search(let key):
            lazy.filter { entry in
                key.isEmpty ||
                entry.message.contains(key) ||
                entry.source.fileID.contains(key) ||
                entry.source.function.contains(key)
            }
        case .tag(let tags):
            filter(by: tags)
        }
    }
}
