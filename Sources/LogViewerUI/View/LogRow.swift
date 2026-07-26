import LogViewerCore
import SwiftUI

internal struct LogRow: View {
    let log: Log
    let isShowFilePath: Bool
    let isShowFunction: Bool
    init(debugLog: Log, isShowFilePath: Bool = true, isShowFunction: Bool = true) {
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
                    indentedText(log.fileID, systemImage: "document")
                }
                if isShowFunction {
                    indentedText(log.function, systemImage: "function")
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

private extension Log {
    var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SS"
        return formatter.string(from: self.time)
    }
}

#Preview {
    let debugLogs: [Log] = [
        .init(
            message: "abcdefg",
            tags: ["test", "abc"],
            fileID: "アイウエオ",
            function: "カキクケコ"
        ),
        .init(
            message: "ABCDEFG",
            tags: ["test", "abcdefg", "日本語", "⭐️", "🟦"],
            fileID: "あいうえお",
            function: "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"
        ),
        .init(
            message: "ABCDEFG",
            tags: ["test", "abcdefg", "日本語", "⭐️", "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"],
            fileID: "あいうえお",
            function: "かきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこかきくけこ"
        ),
    ]
    List(debugLogs) { debugLog in
        LogRow(
            debugLog: debugLog
        )
    }
    .scrollContentBackground(.hidden)
}
