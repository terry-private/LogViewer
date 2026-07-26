import Testing
import LogViewerCore

@Suite("LogViewerCore Public API")
struct CorePublicAPITests {
    @Test("中核製品だけで公開ログモデルを作成できる")
    func coreProductCreatesPublicLogModel() {
        let entry = LogEntry(
            level: .notice,
            message: "Settings changed",
            source: SourceLocation(
                fileID: "Settings.swift",
                function: "save()",
                line: 12
            ),
            category: "settings",
            tags: ["user"],
            metadata: ["screen": "general"]
        )

        #expect(entry.level == .notice)
        #expect(entry.source.line == 12)
    }

    @Test("MainActor以外から共有ロガーへ記録できる")
    func sharedLoggerRecordsOutsideMainActor() async {
        let store = InMemoryLogStore()
        let logger = Logger(store: store)

        await Task.detached {
            logger.add(
                "background",
                fileID: "Worker.swift",
                function: "run()",
                line: 8
            )
        }.value

        #expect(store.snapshot().entries.map(\.message) == ["background"])
    }

    @Test("利用側で保存機能を差し替えられる")
    func customStoreConformanceCompiles() {
        let logger = Logger(store: EmptyLogStore())

        logger.add(
            "custom",
            fileID: "Custom.swift",
            function: "add()",
            line: 1
        )
    }
}

private struct EmptyLogStore: LogStore {
    func snapshot() -> LogStoreSnapshot {
        LogStoreSnapshot(entries: [], isRecordingEnabled: true)
    }

    func updates() -> AsyncStream<LogStoreSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot())
            continuation.finish()
        }
    }

    func add(_ entry: LogEntry) {}
    func setRecordingEnabled(_ isEnabled: Bool) {}
    func deleteAll() {}
}
