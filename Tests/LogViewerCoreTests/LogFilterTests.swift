import Foundation
import Testing
@testable import LogViewerCore

@Suite("複合ログ絞り込み", .serialized)
struct LogFilterTests {
    private let referenceDate = Date(timeIntervalSince1970: 1_000_000)

    @Test("条件が空なら全ログを追加順で返す")
    func emptyFilterPreservesInsertionOrder() {
        let logs = makeLogs()

        #expect(logs.filter(by: .all).map(\.message) == [
            "Request completed",
            "Failed to decode response",
            "Café button tapped",
            "Untagged event",
        ])
    }

    @Test(
        "検索はメッセージ・ファイル・関数を地域設定に沿って照合する",
        arguments: [
            ("REQUEST", ["Request completed"]),
            ("apiclient", [
                "Request completed",
                "Failed to decode response",
            ]),
            ("DIDTAPBUTTON", ["Café button tapped"]),
            ("cafe", ["Café button tapped"]),
            ("missing", []),
            ("  ", [
                "Request completed",
                "Failed to decode response",
                "Café button tapped",
                "Untagged event",
            ]),
        ]
    )
    func searchMatchesVisibleFields(
        key: String,
        expectedMessages: [String]
    ) {
        #expect(
            makeLogs().filter(by: .search(key)).map(\.message)
                == expectedMessages
        )
    }

    @Test("文字列・ログ水準・タグ・期間をANDで組み合わせる")
    func combinesEveryFilterDimension() {
        let candidates = [
            makeEntry(
                level: .error,
                message: "Target response",
                fileID: "API.swift",
                function: "send()",
                tags: ["network", "error"],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .error,
                message: "Wrong search",
                fileID: "API.swift",
                function: "send()",
                tags: ["network", "error"],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .info,
                message: "Wrong level response",
                fileID: "API.swift",
                function: "send()",
                tags: ["network", "error"],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .error,
                message: "Wrong tags response",
                fileID: "API.swift",
                function: "send()",
                tags: ["network"],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .error,
                message: "Wrong period response",
                fileID: "API.swift",
                function: "send()",
                tags: ["network", "error"],
                secondsFromReference: -360
            ),
        ]
        let filter = LogFilter(
            searchText: "response",
            levels: [.error],
            tags: ["network", "error"],
            tagMatchMode: .all,
            period: .lastFiveMinutes
        )

        #expect(
            candidates.filter(by: filter, now: referenceDate).map(\.message)
                == ["Target response"]
        )
    }

    @Test("タグのORとANDを明示的に切り替える")
    func switchesTagMatchMode() {
        let logs = makeLogs()
        let anyFilter = LogFilter(
            tags: ["network", "ui"],
            tagMatchMode: .any
        )
        let allFilter = LogFilter(
            tags: ["network", "api"],
            tagMatchMode: .all
        )

        #expect(logs.filter(by: anyFilter).map(\.message) == [
            "Request completed",
            "Failed to decode response",
            "Café button tapped",
        ])
        #expect(logs.filter(by: allFilter).map(\.message) == [
            "Request completed",
        ])
    }

    @Test("空のログ水準とタグは条件なしとして扱う")
    func emptySelectionsDoNotFilter() {
        let filter = LogFilter(levels: [], tags: [], tagMatchMode: .all)

        #expect(makeLogs().filter(by: filter).count == 4)
    }

    @Test("相対期間は現在時刻に追従し、両端を含み未来を除く")
    func relativePeriodMovesWithCurrentTime() {
        let filter = LogFilter(period: .lastFiveMinutes)
        let logs = [
            makeEntry(
                level: .info,
                message: "lower boundary",
                fileID: "Time.swift",
                function: "run()",
                tags: [],
                secondsFromReference: -300
            ),
            makeEntry(
                level: .info,
                message: "upper boundary",
                fileID: "Time.swift",
                function: "run()",
                tags: [],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .info,
                message: "future",
                fileID: "Time.swift",
                function: "run()",
                tags: [],
                secondsFromReference: 1
            ),
        ]

        #expect(logs.filter(by: filter, now: referenceDate).map(\.message) == [
            "lower boundary",
            "upper boundary",
        ])
        #expect(logs.filter(
            by: filter,
            now: referenceDate.addingTimeInterval(301)
        ).isEmpty)
    }

    @Test("検索は注入した地域設定に従う")
    func searchUsesInjectedLocale() {
        let logs = [makeEntry(
            level: .info,
            message: "I",
            fileID: "Locale.swift",
            function: "run()",
            tags: [],
            secondsFromReference: 0
        )]

        #expect(logs.filter(
            by: .search("ı"),
            locale: Locale(identifier: "tr_TR")
        ).count == 1)
        #expect(logs.filter(
            by: .search("i"),
            locale: Locale(identifier: "tr_TR")
        ).isEmpty)
    }

    @Test("各相対期間の遷移日時を表示粒度へ切り上げる")
    func roundsTransitionDateForEveryPeriod() {
        let now = Date(timeIntervalSince1970: 1_000_000.25)

        #expect(LogFilterPeriod.lastFiveMinutes.transitionDate(
            for: now,
            now: now
        ) == Date(timeIntervalSince1970: 1_000_301))
        #expect(LogFilterPeriod.lastHour.transitionDate(
            for: now,
            now: now
        ) == Date(timeIntervalSince1970: 1_003_610))
        #expect(LogFilterPeriod.lastDay.transitionDate(
            for: now,
            now: now
        ) == Date(timeIntervalSince1970: 1_086_420))

        let future = Date(timeIntervalSince1970: 1_000_010.45)
        #expect(LogFilterPeriod.lastFiveMinutes.transitionDate(
            for: future,
            now: now
        ) == Date(timeIntervalSince1970: 1_000_011))
        #expect(LogFilterPeriod.all.transitionDate(
            for: now,
            now: now
        ) == nil)
    }

    private func makeLogs() -> [LogEntry] {
        [
            makeEntry(
                level: .info,
                message: "Request completed",
                fileID: "Networking/APIClient.swift",
                function: "send()",
                tags: ["network", "api"],
                secondsFromReference: -120
            ),
            makeEntry(
                level: .error,
                message: "Failed to decode response",
                fileID: "Networking/APIClient.swift",
                function: "decode()",
                tags: ["network", "error"],
                secondsFromReference: -60
            ),
            makeEntry(
                level: .notice,
                message: "Café button tapped",
                fileID: "Features/HomeView.swift",
                function: "didTapButton()",
                tags: ["ui"],
                secondsFromReference: 0
            ),
            makeEntry(
                level: .debug,
                message: "Untagged event",
                fileID: "App.swift",
                function: "start()",
                tags: [],
                secondsFromReference: 60
            ),
        ]
    }

    private func makeEntry(
        level: LogLevel,
        message: String,
        fileID: String,
        function: String,
        tags: [LogViewerCore.Tag],
        secondsFromReference: TimeInterval
    ) -> LogEntry {
        LogEntry(
            level: level,
            message: message,
            source: SourceLocation(
                fileID: fileID,
                function: function,
                line: 1
            ),
            tags: tags,
            timestamp: referenceDate.addingTimeInterval(secondsFromReference)
        )
    }
}
