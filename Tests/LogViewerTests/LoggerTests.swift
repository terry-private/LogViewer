import Testing
@testable import LogViewer

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
        #expect(logger.logs[0].fileID == "Networking/APIClient.swift")
        #expect(logger.logs[0].function == "send()")
    }

    @Test("add captures the default caller source context")
    func addCapturesDefaultCallerSourceContext() {
        let logger = Logger()

        addFromSourceContextHelper(to: logger)

        #expect(logger.logs.count == 1)
        #expect(logger.logs[0].fileID.hasSuffix("LoggerTests.swift"))
        #expect(
            logger.logs[0].function
                == "addFromSourceContextHelper(to:)"
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

    private func addFromSourceContextHelper(to logger: Logger) {
        logger.add("default source")
    }
}
