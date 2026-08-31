import Foundation
import Testing
@testable import LogViewerCore

@Suite("ログ書き出し")
struct LogExporterTests {
    @Test("テキストは渡したログだけを安定した順序で出力する")
    func exportsPlainTextDeterministically() throws {
        let entry = makeEntry(
            message: "Request failed",
            metadata: ["z": "last", "a": "first"]
        )
        let text = try LogExporter().string(
            from: [entry],
            format: .plainText
        )

        #expect(text == "1970-01-01T00:16:40.125Z level=ERROR "
            + "message=\"Request failed\" file=\"API.swift\" line=42 "
            + "function=\"send()\" category=\"network\" "
            + "tags=[\"api\",\"error\"] "
            + "metadata={\"a\":\"first\",\"z\":\"last\"}")
    }

    @Test("JSON仕様はLogEntry配列をISO 8601日時で出力する")
    func exportsJSONSchema() throws {
        let entry = makeEntry(message: "Request failed")
        let data = try LogExporter().data(from: [entry], format: .json)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )
        let exported = try #require(object.first)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds,
            ]
            guard let date = formatter.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid fractional ISO 8601 date"
                )
            }
            return date
        }
        let decoded = try decoder.decode([LogEntry].self, from: data)

        #expect(object.count == 1)
        #expect(Set(exported.keys) == [
            "id", "level", "message", "source", "category",
            "tags", "metadata", "timestamp",
        ])
        #expect(decoded == [entry])
        #expect(exported["timestamp"] as? String
            == "1970-01-01T00:16:40.125Z")
    }

    @Test("テキストとJSONの両方へ書き出し直前の秘匿化を適用する")
    func redactsEveryExportFormat() throws {
        let entries = [makeEntry(
            message: "owner@example.com Bearer abc.def",
            metadata: ["password": "raw-password"]
        )]
        let exporter = LogExporter(privacyPolicy: .standard)

        for format in [LogExportFormat.plainText, .json] {
            let exported = try exporter.string(from: entries, format: format)
            #expect(exported.contains("<private>"))
            #expect(!exported.contains("owner@example.com"))
            #expect(!exported.contains("abc.def"))
            #expect(!exported.contains("raw-password"))
        }
    }

    @Test("空の選択は空のテキストと空配列JSONになる")
    func exportsEmptySelection() throws {
        let exporter = LogExporter()

        #expect(try exporter.string(
            from: [],
            format: .plainText
        ).isEmpty)
        let json = try exporter.data(from: [], format: .json)
        let object = try #require(
            JSONSerialization.jsonObject(with: json) as? [Any]
        )
        #expect(object.isEmpty)
    }

    @Test("制御文字と区切りを引用して1件を必ず1行にする")
    func escapesPlainTextFields() throws {
        let entry = LogEntry(
            message: "first\nsecond \"quoted\" \\ path",
            source: SourceLocation(
                fileID: "File\rName.swift",
                function: "run\tvalue=1,2",
                line: 7
            ),
            category: "cat,value",
            tags: ["tag=one"],
            metadata: ["key,one": "value=two\nnext"],
            timestamp: Date(timeIntervalSince1970: 1_000.125)
        )

        let text = try LogExporter().string(
            from: [entry],
            format: .plainText
        )

        #expect(text.split(separator: "\n").count == 1)
        #expect(text.contains(#"first\nsecond \"quoted\" \\ path"#))
        #expect(text.contains(#"file="File\rName.swift""#))
        #expect(text.contains(#"function="run\tvalue=1,2""#))
        #expect(text.contains(#"metadata={"key,one":"value=two\nnext"}"#))
    }

    @Test("バージョン1のJSON fixtureと互換で未知の項目を無視する")
    func maintainsVersionOneJSONCompatibility() throws {
        let fixtureURL = try #require(
            Bundle.module.url(
                forResource: "log-entry-v1",
                withExtension: "json"
            )
        )
        let fixture = try Data(contentsOf: fixtureURL)
        let expected = makeEntry(
            message: "Request failed",
            metadata: ["request-id": "42"]
        )
        let exported = try LogExporter().data(
            from: [expected],
            format: .json
        )

        #expect(try jsonObject(exported) == jsonObject(fixture))

        var object = try #require(
            jsonObject(fixture) as? [[String: Any]]
        )
        object[0]["futureField"] = "ignored"
        let futureJSON = try JSONSerialization.data(withJSONObject: object)
        #expect(try decoder().decode([LogEntry].self, from: futureJSON)
            == [expected])
    }

    @Test("JSON v1はcategoryがnilならキーを省略して復号できる")
    func omitsNilCategoryInVersionOneJSON() throws {
        let entry = LogEntry(
            message: "No category",
            source: SourceLocation(
                fileID: "API.swift",
                function: "send()",
                line: 42
            ),
            category: nil,
            timestamp: Date(timeIntervalSince1970: 1_000.125)
        )
        let data = try LogExporter().data(from: [entry], format: .json)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )

        #expect(object.first?["category"] == nil)
        #expect(try decoder().decode([LogEntry].self, from: data) == [entry])
    }

    private func makeEntry(
        message: String,
        metadata: [String: String] = [:]
    ) -> LogEntry {
        LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
            level: .error,
            message: message,
            source: SourceLocation(
                fileID: "API.swift",
                function: "send()",
                line: 42
            ),
            category: "network",
            tags: ["api", "error"],
            metadata: metadata,
            timestamp: Date(timeIntervalSince1970: 1_000.125)
        )
    }

    private func jsonObject(_ data: Data) throws -> AnyHashable {
        try #require(
            JSONSerialization.jsonObject(with: data) as? AnyHashable
        )
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = try? Date(
                value,
                strategy: .iso8601
            ) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO 8601 timestamp"
                )
            }
            return date
        }
        return decoder
    }
}
