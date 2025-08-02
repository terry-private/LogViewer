import SwiftUI

struct LogFilterView: View {
    @Binding var filter: LogFilter
    @State var searchText: String = ""
    @State var selectedTags: Set<Tag> = []
    let allTags: [Tag]
    var body: some View {
        if #available(iOS 26, *) {
            content
                .glassEffect()
        } else {
            content
        }
    }

    @ViewBuilder
    var content: some View {
        HStack {
            Menu {
                ForEach(LogFilterItem.allCases, id: \.self) { item in
                    Button {
                        update(item: item)
                    } label: {
                        item.label
                    }
                }
            } label: {
                Image(systemName: filter.item.systemImageName)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background {
                        Circle()
                    }
            }
            Text("")
                .padding(10)
                .frame(maxWidth: .infinity)
                .overlay {
                    switch filter {
                    case .all:
                        Text("All logs")
                        Spacer()
                    case .search:
                        TextField("Search", text: $searchText)
                            .onChange(of: searchText) {_, _ in
                                if case .search = filter {
                                    update(item: .search)
                                }
                            }
                    case .tag:
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(allTags, id: \.self) { tag in
                                    tagButton(tag)
                                }
                            }
                        }
                        .padding(.vertical, -5)
                    }
                }
        }
    }

    @ViewBuilder
    func tagButton(_ tag: Tag) -> some View {
        Button {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
            if case .tag = filter {
                update(item: .tag)
            }
        } label: {
            Text(tag.rawValue)
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background {
                    Capsule()
                        .foregroundStyle(selectedTags.contains(tag) ? Color.accentColor : Color.secondary)
                }

        }
    }

    func update(item: LogFilterItem) {
        switch item {
        case .all:
            filter = .all
        case .search:
            filter = .search(searchText)
        case .tag:
            filter = .tag(selectedTags)
        }
    }
}

enum LogFilterItem: CaseIterable, Hashable, Sendable {
    case all, tag, search

    var systemImageName: String {
        switch self {
        case .all: "checklist.checked"
        case .search: "magnifyingglass"
        case .tag: "tag"
        }
    }

    var title: String {
        switch self {
        case .all: "All"
        case .search: "Search"
        case .tag: "Tag"
        }
    }

    var label: some View {
        Label(title, systemImage: systemImageName)
    }
}

extension LogFilter {
    var item: LogFilterItem {
        switch self {
        case .all: .all
        case .search: .search
        case .tag: .tag
        }
    }
}

#Preview {
    @Previewable @State var filter: LogFilter = .all
    VStack {
        Spacer()

        if #available(iOS 26, *) {
            LogFilterView(filter: $filter, allTags: ["api", "error"])
                .glassEffect()
        } else {
            LogFilterView(filter: $filter, allTags: ["api", "error"])
        }
    }
}
