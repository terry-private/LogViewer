import Foundation
import Testing
@testable import LogViewerUI

@Suite("ログ日時の地域対応")
@MainActor
struct LogTimestampFormatterTests {
    @Test("同じ地域ではFormatterを共有し地域ごとに分離する")
    func cachesFormatterByLocale() {
        let english = Locale(identifier: "en_US")
        let japanese = Locale(identifier: "ja_JP")
        let firstEnglish = LogTimestampFormatter.formatter(for: english)
        let secondEnglish = LogTimestampFormatter.formatter(for: english)
        let japaneseFormatter = LogTimestampFormatter.formatter(for: japanese)

        #expect(firstEnglish === secondEnglish)
        #expect(firstEnglish !== japaneseFormatter)
        #expect(firstEnglish.locale.identifier == english.identifier)
        #expect(japaneseFormatter.locale.identifier == japanese.identifier)
        #expect(firstEnglish.dateFormat.contains("a"))
        #expect(firstEnglish.dateFormat.contains("h"))
        #expect(!firstEnglish.dateFormat.contains("H"))
        for component in ["y", "M", "d", "m", "s", "S"] {
            #expect(firstEnglish.dateFormat.contains(component))
            #expect(japaneseFormatter.dateFormat.contains(component))
        }
    }

    @Test("英語と日本語の日時表現を現在地域に合わせる")
    func formatsDateForRequestedLocale() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let english = LogTimestampFormatter.string(
            from: date,
            locale: Locale(identifier: "en_US")
        )
        let japanese = LogTimestampFormatter.string(
            from: date,
            locale: Locale(identifier: "ja_JP")
        )

        #expect(!english.isEmpty)
        #expect(!japanese.isEmpty)
        #expect(english != japanese)
    }
}
