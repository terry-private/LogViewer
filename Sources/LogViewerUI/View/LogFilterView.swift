import Foundation
import LogViewerCore
import SwiftUI

struct LogFilterView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                adaptiveContent.glassEffect()
            } else {
                adaptiveContent
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

    @ViewBuilder
    private var adaptiveContent: some View {
        if LogViewerAccessibilityPolicy.adaptiveLayout(
            for: dynamicTypeSize
        ).usesScrollableFilter {
            ScrollView(.vertical) {
                content
            }
            .frame(maxHeight: 260)
        } else {
            content
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
                .accessibilityHidden(true)
            TextField(
                LogViewerLocalization.string(.filterSearchPlaceholder),
                text: $searchText
            )
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
                .accessibilityLabel(
                    LogViewerLocalization.string(
                        .accessibilityClearSearch
                    )
                )
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
                Label(
                    LogViewerLocalization.string(.filterTags),
                    systemImage: "tag"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button {
                        filter.tagMatchMode = .any
                    } label: {
                        Label(
                            LogViewerLocalization.string(.filterTagsAny),
                            systemImage: filter.tagMatchMode == .any
                                ? "checkmark"
                                : "circle"
                        )
                    }
                    Button {
                        filter.tagMatchMode = .all
                    } label: {
                        Label(
                            LogViewerLocalization.string(.filterTagsAll),
                            systemImage: filter.tagMatchMode == .all
                                ? "checkmark"
                                : "circle"
                        )
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
        ViewThatFits(in: .horizontal) {
            HStack {
                periodMenu
                Spacer()
                resultCountText
                clearFilterButton
            }
            VStack(alignment: .leading, spacing: 8) {
                periodMenu
                HStack {
                    resultCountText
                    Spacer()
                    clearFilterButton
                }
            }
        }
    }

    private var periodMenu: some View {
        Menu {
            ForEach(LogFilterPeriod.allCases, id: \.self) { period in
                Button {
                    filter.period = period
                } label: {
                    Label(
                        period.title,
                        systemImage: filter.period == period
                            ? "checkmark"
                            : "circle"
                    )
                }
            }
        } label: {
            Label(filter.period.title, systemImage: "calendar")
                .font(.caption)
        }
    }

    private var resultCountText: some View {
        Text(LogViewerLocalization.resultCount(
            resultCount,
            totalCount: totalCount
        ))
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var clearFilterButton: some View {
        if filter.isActive {
            Button(
                LogViewerLocalization.string(.filterClear)
            ) {
                filter = .all
                searchText = ""
            }
            .font(.caption)
        }
    }

    private func filterButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let selection = LogViewerAccessibilityPolicy.selectionPresentation(
            isSelected: isSelected
        )
        return Button(action: action) {
            HStack(spacing: 4) {
                if selection.showsCheckmark {
                    Image(systemName: "checkmark")
                }
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? Color.accentColor
                    : Color.secondary.opacity(0.15),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(
            selection.isAccessibilitySelected ? .isSelected : []
        )
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
        case .trace: LogViewerLocalization.string(.levelTrace)
        case .debug: LogViewerLocalization.string(.levelDebug)
        case .info: LogViewerLocalization.string(.levelInfo)
        case .notice: LogViewerLocalization.string(.levelNotice)
        case .warning: LogViewerLocalization.string(.levelWarning)
        case .error: LogViewerLocalization.string(.levelError)
        case .critical: LogViewerLocalization.string(.levelCritical)
        }
    }
}

private extension TagMatchMode {
    var title: String {
        switch self {
        case .any: LogViewerLocalization.string(.filterMatchAny)
        case .all: LogViewerLocalization.string(.filterMatchAll)
        }
    }
}

private extension LogFilterPeriod {
    var title: String {
        switch self {
        case .all: LogViewerLocalization.string(.filterPeriodAll)
        case .lastFiveMinutes:
            LogViewerLocalization.string(.filterPeriodLast5Minutes)
        case .lastHour:
            LogViewerLocalization.string(.filterPeriodLastHour)
        case .lastDay:
            LogViewerLocalization.string(.filterPeriodLast24Hours)
        }
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
