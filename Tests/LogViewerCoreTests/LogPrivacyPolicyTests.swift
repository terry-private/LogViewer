import Foundation
import Testing
@testable import LogViewerCore

@Suite("ログの秘匿化方針")
struct LogPrivacyPolicyTests {
    @Test("標準方針を本文と全公開文字列へ適用する")
    func standardPolicyRedactsVisibleStrings() {
        let entry = makeEntry(
            message: "mail user@example.com with Bearer abc.def-123",
            metadata: [
                "Authorization": "Bearer raw-secret",
                "note": "contact owner@example.com",
            ]
        )

        let redacted = LogPrivacyPolicy.standard.redacting(entry)

        #expect(redacted.message == "mail <private> with <private>")
        #expect(redacted.source.fileID == "<private> File.swift")
        #expect(redacted.source.function == "send(<private>)")
        #expect(redacted.category == "account:<private>")
        #expect(redacted.tags == ["owner:<private>"])
        #expect(redacted.metadata["Authorization"] == "<private>")
        #expect(redacted.metadata["note"] == "contact <private>")
        #expect(entry.message.contains("user@example.com"))
    }

    @Test("付加情報をキー単位で伏せ字または削除する")
    func controlsMetadataExposureByKey() {
        let policy = LogPrivacyPolicy(
            redactedMetadataKeys: ["token"],
            removedMetadataKeys: ["internal_id"],
            metadataReplacement: "***"
        )
        let redacted = policy.redacting(makeEntry(metadata: [
            "TOKEN": "secret",
            "internal_ID": "42",
            "status": "200",
        ]))

        #expect(redacted.metadata == [
            "TOKEN": "***",
            "status": "200",
        ])
    }

    @Test("付加情報キーも秘匿化し衝突しても項目を保持する")
    func redactsMetadataKeysWithoutDroppingCollisions() {
        let redacted = LogPrivacyPolicy.standard.redacting(
            makeEntry(metadata: [
                "first@example.com": "first",
                "second@example.com": "second",
            ])
        )

        #expect(redacted.metadata == [
            "<private>": "first",
            "<private>#2": "second",
        ])
        #expect(!String(describing: redacted.metadata).contains("@"))
    }

    @Test("独自の文字列規則を安全に適用する")
    func appliesCustomLiteralRule() throws {
        let rule = try LogRedactionRule(
            matching: "customer-123",
            replacement: "customer-***"
        )
        let policy = LogPrivacyPolicy(rules: [rule])

        #expect(policy.redacting(
            makeEntry(message: "customer-123")
        ).message == "customer-***")
        #expect(throws: (any Error).self) {
            _ = try LogRedactionRule(matching: "")
        }
    }

    @Test("置換文字列を正規表現テンプレートとして解釈しない")
    func treatsReplacementAsLiteral() throws {
        let rule = try LogRedactionRule(
            matching: "secret",
            replacement: #"$0\mask"#
        )
        let redacted = LogPrivacyPolicy(rules: [rule]).redacting(
            makeEntry(message: "secret")
        )

        #expect(redacted.message == #"$0\mask"#)
        #expect(!redacted.message.contains("secret"))
    }

    @Test("置換値と同じ未加工文字列も後続規則で秘匿化する")
    func doesNotTrustReplacementLikeInput() throws {
        let policy = LogPrivacyPolicy(rules: [
            try LogRedactionRule(
                matching: "secret",
                replacement: "owner@example.com"
            ),
            .emailAddress,
        ])

        #expect(policy.redacting(
            makeEntry(message: "owner@example.com")
        ).message == "<private>")
        #expect(policy.redacting(
            makeEntry(message: "secret")
        ).message == "<private>")
    }

    @Test("保存前秘匿化では秘密値をStoreへ保持しない")
    func storeDoesNotRetainSecrets() {
        let store = InMemoryLogStore(privacyPolicy: .standard)
        store.add(makeEntry(
            message: "user@example.com",
            metadata: ["token": "raw-token"]
        ))

        let stored = store.snapshot().entries[0]
        #expect(stored.message == "<private>")
        #expect(stored.metadata == ["token": "<private>"])
        #expect(!String(describing: stored).contains("raw-token"))
        #expect(!String(describing: stored).contains("user@example.com"))
    }

    @Test("同じ方針で並行追加したログをすべて秘匿化する")
    func concurrentlyRedactsStoreEntries() async {
        let store = InMemoryLogStore(
            maximumEntryCount: 1_000,
            privacyPolicy: .standard
        )

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<1_000 {
                group.addTask {
                    store.add(LogEntry(
                        message: "user\(index)@example.com Bearer token\(index)",
                        source: SourceLocation(
                            fileID: "Worker.swift",
                            function: "run()",
                            line: UInt(index)
                        ),
                        metadata: ["token": "raw-\(index)"]
                    ))
                }
            }
        }

        let entries = store.snapshot().entries
        #expect(entries.count == 1_000)
        #expect(entries.allSatisfy { entry in
            entry.message == "<private> <private>"
                && entry.metadata == ["token": "<private>"]
        })
    }

    private func makeEntry(
        message: String = "message",
        metadata: [String: String] = [:]
    ) -> LogEntry {
        LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
            level: .error,
            message: message,
            source: SourceLocation(
                fileID: "Owner-owner@example.com File.swift",
                function: "send(owner@example.com)",
                line: 13
            ),
            category: "account:owner@example.com",
            tags: ["owner:owner@example.com"],
            metadata: metadata,
            timestamp: Date(timeIntervalSince1970: 1_000)
        )
    }
}
