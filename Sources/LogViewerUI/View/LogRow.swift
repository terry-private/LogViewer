import LogViewerCore
import SwiftUI

internal struct LogRow: View {
    @Environment(\.locale) private var locale
    let log: LogEntry
    let isShowFilePath: Bool
    let isShowFunction: Bool
    init(debugLog: LogEntry, isShowFilePath: Bool = true, isShowFunction: Bool = true) {
        self.log = debugLog
        self.isShowFilePath = isShowFilePath
        self.isShowFunction = isShowFunction
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text(LogTimestampFormatter.string(
                from: log.timestamp,
                locale: locale
            ))
                .foregroundStyle(.secondary)
            Grid(alignment: .leading) {
                if isShowFilePath {
                    indentedText(log.source.fileID, systemImage: "document")
                }
                if isShowFunction {
                    indentedText(log.source.function, systemImage: "function")
                }
            }
            if !log.tags.isEmpty {
                FlowLayout(alignment: .leading, spacing: 4) {
                    ForEach(log.tags, id: \.self) { tag in
                        Text(tag.rawValue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .foregroundStyle(.secondary)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary)
                            }
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Text(log.message)
        }
        .font(.caption)
        .multilineTextAlignment(.leading)
        .textSelection(.enabled)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }
}

extension LogRow {
    @ViewBuilder
    func indentedText(_ text: String, systemImage: String) -> some View {
        GridRow(alignment: .firstTextBaseline) {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
            Text(text)
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    func tagView(_ tag: Tag) -> some View {
        Text(tag.rawValue)
            .font(.caption)
            .padding(3)
            .background {
                RoundedRectangle(cornerRadius: 6)
            }
            .foregroundColor(.blue)
    }
}

@MainActor
enum LogTimestampFormatter {
    private static var formatters: [String: DateFormatter] = [:]

    static func string(from date: Date, locale: Locale) -> String {
        formatter(for: locale).string(from: date)
    }

    static func formatter(for locale: Locale) -> DateFormatter {
        if let formatter = formatters[locale.identifier] {
            return formatter
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("yMdjmsSS")
        formatters[locale.identifier] = formatter
        return formatter
    }
}

#Preview {
    let debugLogs: [LogEntry] = [
        .init(
            message: "abcdefg",
            source: .init(
                fileID: "アイウエオ",
                function: "カキクケコ"
            ),
            tags: ["test", "abc"]
        ),
        .init(
            message: "ABCDEFG",
            source: .init(
                fileID: "あいうえお",
                function: "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"
            ),
            tags: ["test", "abcdefg", "日本語", "⭐️", "🟦"]
        ),
        .init(
            message: "ABCDEFG",
            source: .init(
                fileID: "あいうえお",
                function: "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"
            ),
            tags: ["test", "abcdefg", "日本語", "⭐️", "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"]
        ),
    ]
    List(debugLogs) { debugLog in
        LogRow(
            debugLog: debugLog
        )
    }
    .scrollContentBackground(.hidden)
}
