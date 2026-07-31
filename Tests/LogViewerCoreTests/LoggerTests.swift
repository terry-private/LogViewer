import Testing
@testable import LogViewerCore

@Suite("Logger互換API", .serialized)
struct LoggerTests {
    @Test("文字列と発生元をログとして保存する")
    func addStoresLogAndSourceContext() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: "network",
            fileID: "Networking/APIClient.swift",
            function: "send()"
        )

        let logs = logger.store.snapshot().entries
        #expect(logs.count == 1)
        #expect(logs[0].message == "request completed")
        #expect(logs[0].tags == ["network"])
        #expect(logs[0].source.fileID == "Networking/APIClient.swift")
        #expect(logs[0].source.function == "send()")
    }

    @Test("既定の呼び出し元情報を取得する")
    func addCapturesDefaultCallerSourceContext() {
        let logger = Logger()

        let expectedLine = addFromSourceContextHelper(to: logger)

        let logs = logger.store.snapshot().entries
        #expect(logs.count == 1)
        #expect(logs[0].source.fileID.hasSuffix("LoggerTests.swift"))
        #expect(
            logs[0].source.function
                == "addFromSourceContextHelper(to:)"
        )
        #expect(logs[0].source.line == expectedLine)
    }

    @Test("可変長タグの文字列追加を公開ログモデルへ変換する")
    func messageAddConvertsToLogEntry() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: "network",
            fileID: "APIClient.swift",
            function: "send()",
            line: 24
        )

        let logs = logger.store.snapshot().entries
        #expect(logs.count == 1)
        #expect(logs[0].level == .info)
        #expect(logs[0].category == nil)
        #expect(logs[0].metadata.isEmpty)
        #expect(logs[0].source.line == 24)
    }

    @Test("タグ配列の文字列追加を公開ログモデルへ変換する")
    func messageAddWithTagArrayConvertsToLogEntry() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: ["network", "network"],
            fileID: "APIClient.swift",
            function: "send()",
            line: 25
        )

        let logs = logger.store.snapshot().entries
        #expect(logs.count == 1)
        #expect(logs[0].level == .info)
        #expect(logs[0].message == "request completed")
        #expect(logs[0].category == nil)
        #expect(logs[0].tags == ["network"])
        #expect(logs[0].metadata.isEmpty)
        #expect(logs[0].source.fileID == "APIClient.swift")
        #expect(logs[0].source.function == "send()")
        #expect(logs[0].source.line == 25)
    }

    @Test("公開ログモデルをそのまま追加する")
    func addsPublicLogEntry() {
        let logger = Logger()
        let entry = LogEntry(
            level: .warning,
            message: "Slow response",
            source: .init(
                fileID: "APIClient.swift",
                function: "send()",
                line: 42
            ),
            category: "network",
            tags: ["performance"],
            metadata: ["duration": "2.4"]
        )

        logger.add(entry)

        #expect(logger.store.snapshot().entries == [entry])
    }

    @Test("注入した保存機能だけへ追加する")
    func usesInjectedStore() {
        let firstStore = InMemoryLogStore()
        let secondStore = InMemoryLogStore()
        let firstLogger = Logger(store: firstStore)
        let secondLogger = Logger(store: secondStore)

        firstLogger.add("first")
        secondLogger.add("second")

        #expect(
            firstStore.snapshot().entries.map(\.message) == ["first"]
        )
        #expect(
            secondStore.snapshot().entries.map(\.message) == ["second"]
        )
    }

    @Test("記録状態と削除を注入した保存機能へ委譲する")
    func delegatesRecordingControlAndDeletion() {
        let store = InMemoryLogStore()
        let logger = Logger(store: store)

        logger.setRecordingEnabled(false)
        logger.add("paused")
        logger.setRecordingEnabled(true)
        logger.add("resumed")

        #expect(
            store.snapshot().entries.map(\.message) == ["resumed"]
        )

        logger.deleteAll()

        #expect(store.snapshot().entries.isEmpty)
    }

    @Test("共有ロガーから共有保存機能を利用する")
    func sharedLoggerUsesSharedStore() {
        Logger.shared.setRecordingEnabled(true)
        Logger.shared.deleteAll()
        defer {
            Logger.shared.setRecordingEnabled(true)
            Logger.shared.deleteAll()
        }

        Logger.shared.add("shared")

        #expect(
            Logger.shared.store.snapshot().entries.map(\.message)
                == ["shared"]
        )
    }

    private func addFromSourceContextHelper(
        to logger: Logger
    ) -> UInt {
        let expectedLine = UInt(#line + 1)
        logger.add("default source")
        return expectedLine
    }
}
