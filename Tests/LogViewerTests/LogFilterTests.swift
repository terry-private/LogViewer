import Testing
@testable import LogViewer

@Suite("Log filtering", .serialized)
@MainActor
struct LogFilterTests {
    @Test("all preserves every log in insertion order")
    func allPreservesInsertionOrder() {
        let logs = makeLogs()

        #expect(logs.filter(by: .all).map(\.message) == [
            "Request completed",
            "Failed to decode response",
            "Button tapped",
            "Untagged event",
        ])
    }

    @Test(
        "search matches message, file, or function and remains case-sensitive",
        arguments: [
            ("decode", ["Failed to decode response"]),
            ("APIClient", ["Request completed", "Failed to decode response"]),
            ("didTapButton", ["Button tapped"]),
            ("request", []),
            ("", [
                "Request completed",
                "Failed to decode response",
                "Button tapped",
                "Untagged event",
            ]),
        ]
    )
    func searchMatchesCurrentFields(
        key: String,
        expectedMessages: [String]
    ) {
        let logs = makeLogs()

        #expect(
            logs.filter(by: .search(key)).map(\.message) == expectedMessages
        )
    }

    @Test("tag filtering uses OR semantics")
    func tagFilteringUsesOrSemantics() {
        let logs = makeLogs()

        let filtered = logs.filter(by: .tag(["network", "ui"]))

        #expect(filtered.map(\.message) == [
            "Request completed",
            "Failed to decode response",
            "Button tapped",
        ])
    }

    @Test("an empty tag selection currently returns only untagged logs")
    func emptyTagSelectionReturnsUntaggedLogs() {
        let logs = makeLogs()

        let filtered = logs.filter(by: .tag([]))

        #expect(filtered.map(\.message) == ["Untagged event"])
    }

    private func makeLogs() -> [Log] {
        let logger = Logger()
        logger.add(
            "Request completed",
            tags: "network", "api",
            fileID: "Networking/APIClient.swift",
            function: "send()"
        )
        logger.add(
            "Failed to decode response",
            tags: "network", "error",
            fileID: "Networking/APIClient.swift",
            function: "decode()"
        )
        logger.add(
            "Button tapped",
            tags: "ui",
            fileID: "Features/HomeView.swift",
            function: "didTapButton()"
        )
        logger.add(
            "Untagged event",
            fileID: "App.swift",
            function: "start()"
        )
        return logger.logs
    }
}
