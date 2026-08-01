import Testing
import LogViewerCore
@testable import LogViewerUI

@Suite("LogViewState performance")
@MainActor
struct LogViewStatePerformanceTests {
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
        let store = InMemoryLogStore(maximumEntryCount: 10_000)
        for index in 0..<10_000 {
            store.add(makeEntry(
                message: index == 9_999 ? "needle" : "log \(index)",
                fileID: "Feature.swift",
                function: "run()",
                tags: ["performance"]
            ))
        }
        let state = LogViewState(store: store)

        let clock = ContinuousClock()
        let start = clock.now
        state.filter = .search("needle")
        let elapsed = start.duration(to: clock.now)

        #expect(elapsed < .seconds(1))
        #expect(state.logs.map(\.message) == ["needle"])
        #expect(state.tags == ["performance"])
        #expect(state.fileTags == ["Feature.swift"])
    }

    private func makeEntry(
        message: String,
        fileID: String,
        function: String,
        tags: [LogViewerCore.Tag]
    ) -> LogEntry {
        LogEntry(
            message: message,
            source: SourceLocation(
                fileID: fileID,
                function: function,
                line: 1
            ),
            tags: tags
        )
    }

    private func waitUntil(
        _ condition: () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(1))
        while !condition(), clock.now < deadline {
            await Task.yield()
        }
    }
}
