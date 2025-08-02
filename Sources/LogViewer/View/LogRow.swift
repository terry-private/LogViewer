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
            if isShowFilePath {
                indentedText(log.fileID)
                    .foregroundStyle(.secondary)
            }
            if isShowFunction {
                indentedText(log.function)
                    .foregroundStyle(.secondary)
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
    func indentedText(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(">")
            Text(text)
        }
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
            debugLog: debugLog
        )
    }
    .scrollContentBackground(.hidden)
}

