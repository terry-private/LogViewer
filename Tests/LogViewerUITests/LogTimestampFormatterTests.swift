import Foundation
import Testing
@testable import LogViewerUI

@Suite("Log timestamp formatter")
@MainActor
struct LogTimestampFormatterTests {
    @Test("全ログ行で同じ日時フォーマッターを共有する")
    func sharesOneFormatterWithStableFormat() {
        let first = LogTimestampFormatter.shared
        let second = LogTimestampFormatter.shared

        #expect(first === second)
        #expect(first.locale.identifier == "en_US_POSIX")
        #expect(first.dateFormat == "yyyy/MM/dd HH:mm:ss.SS")
        #expect(
            first.string(from: Date(timeIntervalSince1970: 0)).count == 22
        )
    }
}
