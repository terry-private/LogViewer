import Foundation
import Testing
import LogViewerCore
@testable import LogViewerUI

@Suite("LogViewState performance")
@MainActor
struct LogViewStatePerformanceTests {
    @Test("結果件数の表示を全件数と組み合わせる")
    func formatsResultCountSummary() {
        #expect(LogViewerLocalization.resultCount(
            12,
            totalCount: 42,
            locale: Locale(identifier: "ja")
        ) == "12 / 42件")
    }

    @Test("表示と書き出しへ同じ秘匿化方針を適用する")
    func redactsDisplayAndExport() throws {
        let store = InMemoryLogStore()
        store.add(LogEntry(
            message: "owner@example.com Bearer abc.def",
            source: SourceLocation(
                fileID: "Account.swift",
                function: "load()",
                line: 1
            ),
            metadata: ["token": "raw-token"]
        ))
        let state = LogViewState(
            store: store,
            privacyPolicy: .standard
        )

        #expect(store.snapshot().entries[0].message.contains("owner@"))
        #expect(state.logs[0].message == "<private> <private>")
        #expect(state.logs[0].metadata == ["token": "<private>"])
        for format in [LogExportFormat.plainText, .json] {
            let exported = try state.exportString(format: format)
            #expect(!exported.contains("owner@example.com"))
            #expect(!exported.contains("abc.def"))
            #expect(!exported.contains("raw-token"))
        }
    }

    @Test("現在の絞り込み結果だけを書き出す")
    func exportsCurrentFilterOnly() throws {
        let store = InMemoryLogStore()
        store.add(makeEntry(
            message: "included",
            fileID: "Included.swift",
            function: "run()",
            tags: ["share"]
        ))
        store.add(makeEntry(
            message: "excluded",
            fileID: "Excluded.swift",
            function: "run()",
            tags: ["private"]
        ))
        let state = LogViewState(store: store)
        state.filter = .tag(["share"])

        let text = try state.exportString(format: .plainText)
        let json = try state.exportString(format: .json)

        #expect(text.contains("included"))
        #expect(!text.contains("excluded"))
        #expect(json.contains("included"))
        #expect(!json.contains("excluded"))
    }

    @Test("複合条件の結果件数とグループを同時に更新する")
    func compositeFilterUpdatesCountsAndGroups() {
        let now = Date.now
        let store = InMemoryLogStore(maximumEntryCount: 3)
        store.add(LogEntry(
            level: .error,
            message: "API request failed",
            source: SourceLocation(
                fileID: "API.swift",
                function: "send()",
                line: 1
            ),
            tags: ["network", "error"],
            timestamp: now
        ))
        store.add(LogEntry(
            level: .info,
            message: "API request completed",
            source: SourceLocation(
                fileID: "API.swift",
                function: "send()",
                line: 2
            ),
            tags: ["network"],
            timestamp: now
        ))
        store.add(LogEntry(
            level: .error,
            message: "Cache failed",
            source: SourceLocation(
                fileID: "Cache.swift",
                function: "load()",
                line: 3
            ),
            tags: ["error"],
            timestamp: now.addingTimeInterval(-3_600)
        ))
        let state = LogViewState(store: store)

        state.filter = LogFilter(
            searchText: "REQUEST",
            levels: [.error],
            tags: ["network", "error"],
            tagMatchMode: .all,
            period: .lastFiveMinutes
        )

        #expect(state.totalCount == 3)
        #expect(state.resultCount == 1)
        #expect(state.logs.map(\.message) == ["API request failed"])
        #expect(state.tags == ["network", "error"])
        #expect(state.fileTags == ["API.swift"])
        #expect(state.functionTags == ["API.swift\n> send()"])
        let expectedExpiration = Date(
            timeIntervalSince1970: ceil(
                now.timeIntervalSince1970 + 5 * 60
            )
        )
        #expect(
            state.nextRelativePeriodTransitionDate(at: now)
                == expectedExpiration
        )

        state.refreshRelativePeriod(at: now.addingTimeInterval(301))

        #expect(state.resultCount == 0)
        #expect(state.fileTags.isEmpty)
        #expect(state.functionTags.isEmpty)
        #expect(
            state.nextRelativePeriodTransitionDate(
                at: now.addingTimeInterval(301)
            ) == nil
        )
    }

    @Test("未来ログの追加で期間待機を再予約する")
    func futureEntryReschedulesRelativePeriod() async {
        let now = Date.now
        let future = now.addingTimeInterval(10)
        let store = InMemoryLogStore(maximumEntryCount: 1)
        let state = LogViewState(store: store)
        let initialRevision = state.periodScheduleRevision

        state.filter = LogFilter(period: .lastFiveMinutes)
        let filterRevision = state.periodScheduleRevision

        #expect(filterRevision > initialRevision)

        let observationTask = Task {
            await state.observeStore()
        }
        defer {
            observationTask.cancel()
        }
        store.add(LogEntry(
            message: "future",
            source: SourceLocation(
                fileID: "Future.swift",
                function: "arrive()",
                line: 1
            ),
            timestamp: future
        ))
        await waitUntil {
            state.totalCount == 1
        }

        #expect(state.periodScheduleRevision > filterRevision)
        #expect(state.logs.isEmpty)
        let expectedArrival = Date(
            timeIntervalSince1970: ceil(future.timeIntervalSince1970)
        )
        #expect(
            state.nextRelativePeriodTransitionDate(at: now)
                == expectedArrival
        )

        state.refreshRelativePeriod(at: future)

        #expect(state.logs.map(\.message) == ["future"])
    }

    @Test("1万件の期間境界を表示粒度ごとにまとめる")
    func coalescesTenThousandPeriodTransitions() {
        let now = Date(timeIntervalSince1970: 1_000_000.25)
        let period = LogFilterPeriod.lastDay
        let transitions = Set((0..<10_000).compactMap { index in
            period.transitionDate(
                for: now.addingTimeInterval(-Double(index) * 8.64),
                now: now
            )
        })

        #expect(transitions.count == 1_441)
    }

    @Test(
        "保持上限による削除後にタグとグループを更新する",
        .timeLimit(.minutes(1))
    )
    func evictionRebuildsTagsAndGroups() async {
        let store = InMemoryLogStore(maximumEntryCount: 2)
        store.add(makeEntry(
            message: "evicted",
            fileID: "Old.swift",
            function: "old()",
            tags: ["old"]
        ))
        store.add(makeEntry(
            message: "kept",
            fileID: "Kept.swift",
            function: "kept()",
            tags: ["kept"]
        ))
        let state = LogViewState(store: store)
        let observationTask = Task {
            await state.observeStore()
        }
        defer {
            observationTask.cancel()
        }

        store.add(makeEntry(
            message: "latest match",
            fileID: "Latest.swift",
            function: "latest()",
            tags: ["latest"]
        ))
        await waitUntil {
            state.logs.map(\.message) == ["kept", "latest match"]
        }

        #expect(state.tags == ["kept", "latest"])
        #expect(state.fileTags == ["Kept.swift", "Latest.swift"])
        #expect(
            state.functionTags
                == ["Kept.swift\n> kept()", "Latest.swift\n> latest()"]
        )
        #expect(state.fileLogs(for: "Old.swift").isEmpty)
        #expect(state.functionLogs(for: "Old.swift\n> old()").isEmpty)
        #expect(
            state.functionLogs(for: "Kept.swift\n> kept()").map(\.message)
                == ["kept"]
        )
        #expect(
            state.functionLogs(for: "Latest.swift\n> latest()")
                .map(\.message) == ["latest match"]
        )

        state.filter = .search("match")

        #expect(state.totalCount == 2)
        #expect(state.resultCount == 1)
        #expect(state.logs.map(\.message) == ["latest match"])
        #expect(
            state.fileLogs(for: "Latest.swift").map(\.message)
                == ["latest match"]
        )
        #expect(state.fileLogs(for: "Kept.swift").isEmpty)
        #expect(
            state.functionLogs(for: "Latest.swift\n> latest()")
                .map(\.message) == ["latest match"]
        )
        #expect(
            state.functionLogs(for: "Kept.swift\n> kept()").isEmpty
        )

        store.deleteAll()
        await waitUntil {
            state.logs.isEmpty && state.tags.isEmpty
        }

        #expect(state.logs.isEmpty)
        #expect(state.totalCount == 0)
        #expect(state.resultCount == 0)
        #expect(state.tags.isEmpty)
        #expect(state.fileTags.isEmpty)
        #expect(state.functionTags.isEmpty)
        #expect(state.fileLogs(for: "Latest.swift").isEmpty)
        #expect(
            state.functionLogs(for: "Latest.swift\n> latest()").isEmpty
        )
    }

    @Test(
        "1万件の検索キャッシュを1秒以内に再構築する",
        .timeLimit(.minutes(1))
    )
    func tenThousandEntrySearchMeetsBaseline() {
        let now = Date.now
        let store = InMemoryLogStore(maximumEntryCount: 10_000)
        for index in 0..<10_000 {
            store.add(makeEntry(
                message: index == 9_999 ? "needle" : "log \(index)",
                fileID: "Feature.swift",
                function: "run()",
                tags: ["performance"],
                level: .info,
                timestamp: now
            ))
        }
        let state = LogViewState(store: store)

        let clock = ContinuousClock()
        let start = clock.now
        state.filter = LogFilter(
            searchText: "needle",
            levels: [.info],
            tags: ["performance"],
            tagMatchMode: .all,
            period: .lastDay
        )
        let elapsed = start.duration(to: clock.now)

        #expect(elapsed < .seconds(1))
        #expect(state.logs.map(\.message) == ["needle"])
        #expect(state.tags == ["performance"])
        #expect(state.fileTags == ["Feature.swift"])
    }

    @Test(
        "1万件を保存前秘匿化して表示と両書き出しへ5秒以内に反映する",
        .timeLimit(.minutes(1))
    )
    func tenThousandPrivateEntriesMeetBaseline() throws {
        let store = InMemoryLogStore(
            maximumEntryCount: 10_000,
            privacyPolicy: .standard
        )
        let clock = ContinuousClock()
        let start = clock.now

        for index in 0..<10_000 {
            store.add(LogEntry(
                message: "user\(index)@example.com Bearer token\(index)",
                source: SourceLocation(
                    fileID: "Privacy.swift",
                    function: "record()",
                    line: UInt(index)
                ),
                metadata: ["token": "raw-\(index)"]
            ))
        }
        let state = LogViewState(store: store)
        let json = try state.exportString(format: .json)
        let text = try state.exportString(format: .plainText)
        let elapsed = start.duration(to: clock.now)

        #expect(elapsed < .seconds(5))
        #expect(state.logs.count == 10_000)
        #expect(state.logs.allSatisfy { entry in
            entry.message == "<private> <private>"
                && entry.metadata == ["token": "<private>"]
        })
        #expect(!json.contains("@example.com"))
        #expect(!json.contains("raw-"))
        #expect(!text.contains("@example.com"))
        #expect(!text.contains("raw-"))
    }

    private func makeEntry(
        message: String,
        fileID: String,
        function: String,
        tags: [LogViewerCore.Tag],
        level: LogLevel = .info,
        timestamp: Date = .now
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
            timestamp: timestamp
        )
    }

    private func waitUntil(
        _ condition: () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while !condition(), clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
