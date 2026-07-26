import Testing
@testable import LogViewerCore

@Suite("Logger", .serialized)
@MainActor
struct LoggerTests {
    @Test("add stores a log and its source context")
    func addStoresLogAndSourceContext() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: "network",
            fileID: "Networking/APIClient.swift",
            function: "send()"
        )

        #expect(logger.logs.count == 1)
        #expect(logger.logs[0].message == "request completed")
        #expect(logger.logs[0].tags == ["network"])
        #expect(logger.logs[0].source.fileID == "Networking/APIClient.swift")
        #expect(logger.logs[0].source.function == "send()")
    }

    @Test("add captures the default caller source context")
    func addCapturesDefaultCallerSourceContext() {
        let logger = Logger()

        let expectedLine = addFromSourceContextHelper(to: logger)

        #expect(logger.logs.count == 1)
        #expect(logger.logs[0].source.fileID.hasSuffix("LoggerTests.swift"))
        #expect(
            logger.logs[0].source.function
                == "addFromSourceContextHelper(to:)"
        )
        #expect(logger.logs[0].source.line == expectedLine)
    }

    @Test("文字列追加を公開ログモデルへ変換する")
    func messageAddConvertsToLogEntry() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: "network",
            fileID: "APIClient.swift",
            function: "send()",
            line: 24
        )

        #expect(logger.logs.count == 1)
        #expect(logger.logs[0].level == .info)
        #expect(logger.logs[0].category == nil)
        #expect(logger.logs[0].metadata.isEmpty)
        #expect(logger.logs[0].source.line == 24)
    }

    @Test("タグ配列の文字列追加も公開ログモデルへ変換する")
    func messageAddWithTagArrayConvertsToLogEntry() {
        let logger = Logger()

        logger.add(
            "request completed",
            tags: ["network", "network"],
            fileID: "APIClient.swift",
            function: "send()",
            line: 25
        )

        #expect(logger.logs.count == 1)
        #expect(logger.logs[0].level == .info)
        #expect(logger.logs[0].message == "request completed")
        #expect(logger.logs[0].category == nil)
        #expect(logger.logs[0].tags == ["network"])
        #expect(logger.logs[0].metadata.isEmpty)
        #expect(logger.logs[0].source.fileID == "APIClient.swift")
        #expect(logger.logs[0].source.function == "send()")
        #expect(logger.logs[0].source.line == 25)
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
            tags: ["performance", "network", "performance"],
            metadata: ["duration": "2.4"]
        )

        logger.add(entry)

        #expect(logger.logs == [entry])
        #expect(Array(logger.tags) == ["performance", "network"])
        #expect(logger.fileLogs(for: "APIClient.swift") == [entry])
        #expect(
            logger.functionLogs(for: "APIClient.swift\n> send()") == [entry]
        )
    }

    @Test("tags keep first-seen order and remove duplicates")
    func tagsAreOrderedAndUnique() {
        let logger = Logger()

        logger.add("first", tags: ["network", "api"])
        logger.add("second", tags: ["api", "ui"])

        #expect(Array(logger.tags) == ["network", "api", "ui"])
    }

    @Test("logs are grouped by file and by file plus function")
    func logsAreGroupedBySource() {
        let logger = Logger()

        logger.add("first", fileID: "Feature.swift", function: "load()")
        logger.add("second", fileID: "Feature.swift", function: "save()")
        logger.add("third", fileID: "Other.swift", function: "load()")

        #expect(logger.fileLogs(for: "Feature.swift").map(\.message) == ["first", "second"])
        #expect(
            logger.functionLogs(for: "Feature.swift\n> load()").map(\.message)
                == ["first"]
        )
        #expect(
            logger.functionLogs(for: "Feature.swift\n> save()").map(\.message)
                == ["second"]
        )
    }

    @Test("paused logger ignores new logs")
    func pausedLoggerIgnoresNewLogs() {
        let logger = Logger()
        logger.add("before pause")

        logger.active = false
        logger.add("while paused")

        #expect(logger.logs.map(\.message) == ["before pause"])
    }

    @Test("deleteAll clears logs, tags, and source indexes")
    func deleteAllClearsEveryIndex() {
        let logger = Logger()
        logger.add(
            "message",
            tags: "api",
            fileID: "API.swift",
            function: "send()"
        )

        logger.deleteAll()

        #expect(logger.logs.isEmpty)
        #expect(logger.tags.isEmpty)
        #expect(logger.fileLogs(for: "API.swift").isEmpty)
        #expect(logger.functionLogs(for: "API.swift\n> send()").isEmpty)
    }

    private func addFromSourceContextHelper(to logger: Logger) -> UInt {
        let expectedLine = UInt(#line + 1)
        logger.add("default source")
        return expectedLine
    }
}
