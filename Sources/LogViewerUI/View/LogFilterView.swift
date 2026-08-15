import Foundation
import LogViewerCore
import SwiftUI

struct LogFilterView: View {
    @Binding var filter: LogFilter
    @State private var searchText: String
    let allTags: [Tag]
    let resultCount: Int
    let totalCount: Int

    init(
        filter: Binding<LogFilter>,
        allTags: [Tag],
        resultCount: Int,
        totalCount: Int
    ) {
        _filter = filter
        _searchText = State(initialValue: filter.wrappedValue.searchText)
        self.allTags = allTags
        self.resultCount = resultCount
        self.totalCount = totalCount
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                content.glassEffect()
            } else {
                content
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(250))
                if filter.searchText != searchText {
                    filter.searchText = searchText
                }
            } catch {
                // 次の入力でTaskが取り消された場合は古い検索語を反映しない。
            }
        }
        .onChange(of: filter.searchText) { _, newValue in
            if searchText != newValue {
                searchText = newValue
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchField
            levelFilters
            if !allTags.isEmpty {
                tagFilters
            }
            footer
        }
        .padding(12)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("メッセージ、ファイル、関数を検索", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var levelFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    filterButton(
                        title: level.filterTitle,
                        isSelected: filter.levels.contains(level)
                    ) {
                        toggle(level, in: &filter.levels)
                    }
                }
            }
        }
    }

    private var tagFilters: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("タグ", systemImage: "tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("いずれかを含む（OR）") {
                        filter.tagMatchMode = .any
                    }
                    Button("すべてを含む（AND）") {
                        filter.tagMatchMode = .all
                    }
                } label: {
                    Text(filter.tagMatchMode.title)
                        .font(.caption)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags, id: \.self) { tag in
                        filterButton(
                            title: tag.rawValue,
                            isSelected: filter.tags.contains(tag)
                        ) {
                            toggle(tag, in: &filter.tags)
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Menu {
                ForEach(LogFilterPeriod.allCases, id: \.self) { period in
                    Button(period.title) {
                        filter.period = period
                    }
                }
            } label: {
                Label(filter.period.title, systemImage: "calendar")
                    .font(.caption)
            }
            Spacer()
            Text(LogFilterSummary.resultCountText(
                resultCount: resultCount,
                totalCount: totalCount
            ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            if filter.isActive {
                Button("解除") {
                    filter = .all
                    searchText = ""
                }
                .font(.caption)
            }
        }
    }

    private func filterButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private func toggle<Value: Hashable>(
        _ value: Value,
        in selection: inout Set<Value>
    ) {
        if selection.contains(value) {
            selection.remove(value)
        } else {
            selection.insert(value)
        }
    }
}

private extension LogLevel {
    var filterTitle: String {
        switch self {
        case .trace: "Trace"
        case .debug: "Debug"
        case .info: "Info"
        case .notice: "Notice"
        case .warning: "Warning"
        case .error: "Error"
        case .critical: "Critical"
        }
    }
}

private extension TagMatchMode {
    var title: String {
        switch self {
        case .any: "OR"
        case .all: "AND"
        }
    }
}

private extension LogFilterPeriod {
    var title: String {
        switch self {
        case .all: "すべての期間"
        case .lastFiveMinutes: "直近5分"
        case .lastHour: "直近1時間"
        case .lastDay: "直近24時間"
        }
    }
}

enum LogFilterSummary {
    static func resultCountText(resultCount: Int, totalCount: Int) -> String {
        "\(resultCount) / \(totalCount)件"
    }
}

#Preview {
    @Previewable @State var filter: LogFilter = .all
    VStack {
        Spacer()
        LogFilterView(
            filter: $filter,
            allTags: ["api", "error", "network"],
            resultCount: 12,
            totalCount: 42
        )
    }
    .padding()
}
