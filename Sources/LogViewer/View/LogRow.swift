import SwiftUI

internal struct LogRow: View {
    let log: Log
    let tags: [Tag]
    let isShowFilePath: Bool
    let isShowFunction: Bool
    init(debugLog: Log, tags: [Tag], isShowFilePath: Bool = true, isShowFunction: Bool = true) {
        self.log = debugLog
        self.tags = tags
        self.isShowFilePath = isShowFilePath
        self.isShowFunction = isShowFunction
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(log.timeText)")
                .foregroundStyle(.secondary)
            if isShowFilePath {
                indentedText(log.fileID, systemImage: "document")
            }
            if isShowFunction {
                indentedText(log.function, systemImage: "function")
            }
            if !tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag.rawValue)
                            .padding(.horizontal, 5)
                            .foregroundStyle(.secondary)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary)
                            }

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
        HStack(alignment: .firstTextBaseline) {
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
            tags: [],
            fileID: "アイウエオ",
            function: "カキクケコ"
        ),
        .init(
            message: "ABCDEFG",
            tags: [],
            fileID: "あいうえお",
            function: "かきくけこ"
        ),
    ]
    List(debugLogs) { debugLog in
        LogRow(
            debugLog: debugLog,
            tags: ["api", "error"]
        )
    }
    .scrollContentBackground(.hidden)
}

