import Foundation
import Testing
@testable import LogViewerUI

@Suite("LogViewerの日英ローカライズ")
struct LogViewerLocalizationTests {
    @Test("型付きキーと文字列カタログを完全一致させる")
    func typedKeysMatchCatalog() throws {
        let catalog = try loadCatalog()
        let typedKeys = Set(LogViewerStringKey.allCases.map(\.rawValue))

        #expect(Set(catalog.strings.keys) == typedKeys)
    }

    @Test("全キーが日英の翻訳済み文字列を持つ")
    func everyKeyHasEnglishAndJapaneseTranslations() throws {
        let catalog = try loadCatalog()

        for key in LogViewerStringKey.allCases {
            let entry = try #require(catalog.strings[key.rawValue])
            for language in ["en", "ja"] {
                let localization = try #require(
                    entry.localizations[language]?.stringUnit
                )
                #expect(localization.state == "translated")
                #expect(!localization.value.isEmpty)
            }
        }
    }

    @Test("重要な操作と状態の文言を日英で固定する")
    func localizesImportantActionsAndStates() {
        let expectations: [
            LogViewerStringKey: (english: String, japanese: String)
        ] = [
            .accessibilityClose: (
                "Close log viewer",
                "ログ画面を閉じる"
            ),
            .recordingPause: ("Pause recording", "記録を一時停止"),
            .recordingResume: ("Resume recording", "記録を再開"),
            .logsDeleteAction: ("Delete all logs", "すべてのログを削除"),
            .emptyNoLogs: ("No logs yet", "ログはまだありません"),
            .emptyNoMatches: (
                "No logs match the current filters",
                "条件に一致するログはありません"
            ),
        ]

        for (key, expected) in expectations {
            #expect(LogViewerLocalization.string(
                key,
                locale: Locale(identifier: "en")
            ) == expected.english)
            #expect(LogViewerLocalization.string(
                key,
                locale: Locale(identifier: "ja")
            ) == expected.japanese)
        }
    }

    @Test("結果件数の英語単数形と複数形を切り替える")
    func formatsResultCountForLocale() {
        #expect(LogViewerLocalization.resultCount(
            1,
            totalCount: 1,
            locale: Locale(identifier: "en")
        ) == "1 / 1 log")
        #expect(LogViewerLocalization.resultCount(
            12,
            totalCount: 42,
            locale: Locale(identifier: "en")
        ) == "12 / 42 logs")
        #expect(LogViewerLocalization.resultCount(
            12,
            totalCount: 42,
            locale: Locale(identifier: "ja")
        ) == "12 / 42件")
    }

    private func loadCatalog() throws -> Catalog {
        let repositoryDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = repositoryDirectory
            .appendingPathComponent("Sources/LogViewerUI/Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return try JSONDecoder().decode(
            Catalog.self,
            from: Data(contentsOf: catalogURL)
        )
    }

    private struct Catalog: Decodable {
        let strings: [String: Entry]
    }

    private struct Entry: Decodable {
        let localizations: [String: Localization]
    }

    private struct Localization: Decodable {
        let stringUnit: StringUnit
    }

    private struct StringUnit: Decodable {
        let state: String
        let value: String
    }
}
