import LogViewerCore
import SwiftUI

internal struct LogRow: View {
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
            Text("\(log.timeText)")
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
    }
}

extension LogRow {
    @ViewBuilder
    func indentedText(_ text: String, systemImage: String) -> some View {
        GridRow(alignment: .firstTextBaseline) {
            Image(systemName: systemImage)
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

private extension LogEntry {
    var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SS"
        return formatter.string(from: timestamp)
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
