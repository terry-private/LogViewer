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
}
