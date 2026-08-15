import Foundation
import LogViewerCore
import LogViewerSwiftLog
import Logging
import Testing

@Suite("SwiftLog接続部品")
struct LogViewerLogHandlerTests {
    private struct MetadataIdentifier: CustomStringConvertible, Sendable {
        let value: Int
        var description: String { "identifier-\(value)" }
    }

    @Test("すべてのログ水準と発生元をLogEntryへ変換する")
    func convertsLevelsAndSourceLocation() {
        let store = InMemoryLogStore()
        var logger = Logging.Logger(label: "com.example.network") { label in
            LogViewerLogHandler(label: label, store: store)
        }
        logger.logLevel = .trace

        for level in Logging.Logger.Level.allCases {
            logger.log(
                level: level,
                "message-\(level)",
                source: "FeatureModule",
                file: "Feature/Client.swift",
                function: "request()",
                line: 42
            )
        }

        let entries = store.snapshot().entries
        #expect(entries.map(\.level) == LogViewerCore.LogLevel.allCases)
        #expect(entries.map(\.message) == [
            "message-trace",
            "message-debug",
            "message-info",
            "message-notice",
            "message-warning",
            "message-error",
            "message-critical",
        ])
        #expect(entries.allSatisfy {
            $0.source == SourceLocation(
                fileID: "Feature/Client.swift",
                function: "request()",
                line: 42
            )
        })
        #expect(entries.allSatisfy {
            $0.category == "com.example.network"
                && $0.metadata[LogViewerLogHandler.sourceMetadataKey]
                    == "FeatureModule"
        })
    }

    @Test("Logger、Provider、呼び出しの順に付加情報を上書きする")
    func mergesMetadataWithExplicitPrecedence() {
        struct SampleError: Error, CustomStringConvertible {
            let description = "request failed"
        }
        let store = InMemoryLogStore()
        let provider = Logging.Logger.MetadataProvider {
            ["provider": "provided", "same": "provider"]
        }
        let handler = LogViewerLogHandler(
            label: "metadata",
            store: store,
            metadata: ["base": "stored", "same": "base"],
            metadataProvider: provider
        )

        handler.log(event: LogEvent(
            level: .error,
            message: "failed",
            error: SampleError(),
            metadata: [
                "same": "explicit",
                "array": ["one", "two"],
                "dictionary": ["b": "2", "a": "1"],
                "nested": [
                    ["z": ["last", "first"], "a": ["inner": "value"]],
                ],
                "convertible": .stringConvertible(MetadataIdentifier(value: 42)),
                LogViewerLogHandler.sourceMetadataKey: "spoofed",
                LogViewerLogHandler.errorMessageMetadataKey: "spoofed",
                LogViewerLogHandler.errorTypeMetadataKey: "spoofed",
            ],
            source: "ActualModule",
            file: "File.swift",
            function: "run()",
            line: 7
        ))

        let metadata = store.snapshot().entries[0].metadata
        #expect(metadata["base"] == "stored")
        #expect(metadata["provider"] == "provided")
        #expect(metadata["same"] == "explicit")
        #expect(metadata["array"] == #"["one","two"]"#)
        #expect(metadata["dictionary"] == #"{"a":"1","b":"2"}"#)
        #expect(metadata["nested"] == #"["{\"a\":\"{\\\"inner\\\":\\\"value\\\"}\",\"z\":\"[\\\"last\\\",\\\"first\\\"]\"}"]"#)
        #expect(metadata["convertible"] == "identifier-42")
        #expect(metadata[LogViewerLogHandler.errorMessageMetadataKey]
            == "request failed")
        #expect(metadata[LogViewerLogHandler.errorTypeMetadataKey]?
            .contains("SampleError") == true)
        #expect(metadata[LogViewerLogHandler.sourceMetadataKey]
            == "ActualModule")
    }

    @Test("Handlerのコピーは水準と付加情報を共有しない")
    func preservesValueSemantics() {
        let store = InMemoryLogStore()
        var first = LogViewerLogHandler(label: "first", store: store)
        first.logLevel = .debug
        first[metadataKey: "owner"] = "first"
        var second = first
        second.logLevel = .error
        second[metadataKey: "owner"] = "second"

        #expect(first.logLevel == .debug)
        #expect(second.logLevel == .error)
        #expect(first[metadataKey: "owner"] == "first")
        #expect(second[metadataKey: "owner"] == "second")
    }

    @Test("設定水準未満を保存せず1回の呼び出しを1件だけ保存する")
    func respectsThresholdWithoutDuplicateRecording() {
        let store = InMemoryLogStore()
        var logger = Logging.Logger(label: "threshold") { label in
            LogViewerLogHandler(label: label, store: store)
        }
        logger.logLevel = .error

        logger.warning("ignored")
        logger.error("stored")

        #expect(store.snapshot().entries.map(\.message) == ["stored"])
    }

    @Test("同じHandlerを使う並行ログを欠落なく保存する")
    func storesConcurrentLogs() async {
        let store = InMemoryLogStore(maximumEntryCount: 1_000)
        let logger = Logging.Logger(label: "concurrent") { label in
            LogViewerLogHandler(label: label, store: store)
        }

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<1_000 {
                group.addTask {
                    logger.info("message-\(index)")
                }
            }
        }

        let messages = Set(store.snapshot().entries.map(\.message))
        let expected = Set((0..<1_000).map { "message-\($0)" })
        #expect(messages == expected)
    }
}
