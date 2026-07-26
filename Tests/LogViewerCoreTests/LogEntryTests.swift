import Foundation
import Testing
@testable import LogViewerCore

@Suite("公開ログモデル")
struct LogEntryTests {
    @Test("すべての公開情報を保持する")
    func storesEveryPublicField() {
        let id = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!
        let timestamp = Date(timeIntervalSince1970: 1_000)
        let source = SourceLocation(
            fileID: "Feature/APIClient.swift",
            function: "send()",
            line: 42
        )

        let entry = LogEntry(
            id: id,
            level: .error,
            message: "Request failed",
            source: source,
            category: "network",
            tags: ["api", "error", "api"],
            metadata: ["status": "500"],
            timestamp: timestamp
        )

        #expect(entry.id == id)
        #expect(entry.level == .error)
        #expect(entry.message == "Request failed")
        #expect(entry.source == source)
        #expect(entry.category == "network")
        #expect(entry.tags == ["api", "error"])
        #expect(entry.metadata == ["status": "500"])
        #expect(entry.timestamp == timestamp)
    }

    @Test("同じ値は等価になる")
    func equalValuesAreEqual() {
        let id = UUID(
            uuidString: "00000000-0000-0000-0000-000000000002"
        )!
        let timestamp = Date(timeIntervalSince1970: 2_000)
        let source = SourceLocation(
            fileID: "Feature/Feature.swift",
            function: "run()",
            line: 10
        )
        let first = LogEntry(
            id: id,
            message: "message",
            source: source,
            timestamp: timestamp
        )
        let second = LogEntry(
            id: id,
            message: "message",
            source: source,
            timestamp: timestamp
        )

        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
    }

    @Test("記録日時の後に識別子で安定して並び替える")
    func sortsByTimestampThenIdentifier() {
        let earlier = LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            message: "earlier",
            source: .init(),
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let laterFirst = LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            message: "later first",
            source: .init(),
            timestamp: Date(timeIntervalSince1970: 2)
        )
        let laterSecond = LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            message: "later second",
            source: .init(),
            timestamp: Date(timeIntervalSince1970: 2)
        )

        #expect(
            [laterSecond, earlier, laterFirst].sorted().map(\.message)
                == ["earlier", "later first", "later second"]
        )
    }

    @Test("日時と識別子が同じ場合も等価性と一致する順序になる")
    func orderingAgreesWithEquality() {
        let id = UUID(
            uuidString: "00000000-0000-0000-0000-000000000006"
        )!
        let timestamp = Date(timeIntervalSince1970: 2)
        let source = SourceLocation(
            fileID: "Feature.swift",
            function: "run()",
            line: 10
        )
        let first = LogEntry(
            id: id,
            level: .info,
            message: "first",
            source: source,
            timestamp: timestamp
        )
        let differentEntries = [
            LogEntry(
                id: id,
                level: .warning,
                message: "first",
                source: source,
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "second",
                source: source,
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: .init(
                    fileID: "Other.swift",
                    function: "run()",
                    line: 10
                ),
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: .init(
                    fileID: "Feature.swift",
                    function: "stop()",
                    line: 10
                ),
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: .init(
                    fileID: "Feature.swift",
                    function: "run()",
                    line: 11
                ),
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: source,
                category: "category",
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: source,
                tags: ["tag"],
                timestamp: timestamp
            ),
            LogEntry(
                id: id,
                message: "first",
                source: source,
                metadata: ["key": "value"],
                timestamp: timestamp
            ),
        ]

        for differentEntry in differentEntries {
            #expect(first != differentEntry)
            #expect(
                (first < differentEntry) != (differentEntry < first)
            )
        }
    }

    @Test("ログ水準を重大度順に並び替える")
    func sortsLevelsBySeverity() {
        #expect(
            Array(LogLevel.allCases.reversed()).sorted()
                == [
                    .trace,
                    .debug,
                    .info,
                    .notice,
                    .warning,
                    .error,
                    .critical,
                ]
        )
    }

    @Test("符号化と復号で値を維持する")
    func codableRoundTripPreservesValue() throws {
        let entry = LogEntry(
            level: .notice,
            message: "User changed settings",
            source: .init(),
            category: "settings",
            tags: ["user"],
            metadata: ["screen": "general"],
            timestamp: Date(timeIntervalSince1970: 3_000)
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(LogEntry.self, from: data)

        #expect(decoded == entry)
    }

    @Test("復号時もタグを最初の出現順で一意にする")
    func decodingNormalizesDuplicateTags() throws {
        let entry = LogEntry(
            message: "message",
            source: .init(),
            tags: ["api"]
        )
        let encoded = try JSONEncoder().encode(entry)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object["tags"] = ["api", "network", "api"]
        let data = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(LogEntry.self, from: data)

        #expect(decoded.tags == ["api", "network"])
    }
}
