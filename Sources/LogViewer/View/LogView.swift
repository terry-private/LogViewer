import Observation
import SwiftUI

internal struct LogView: View {
    @State var viewState: LogViewState
    @FocusState var focus: Bool
    @State var autoScroll: Bool = true
    let dismiss: () -> Void

    init(isTransparent: Bool = false, dismiss: @escaping () -> Void) {
        viewState = .init(isTransparent: isTransparent)
        self.dismiss = dismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            headerContent

            ScrollViewReader { proxy in
                listContent
                    .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
                        geometry
                    } action: { oldGeometry, newGeometry in
                        // スクロール位置が一番下ら辺にきたらオートスクロール
                        // ちょっと上にスクロールしたらオートスクロールをオフ
                        let isAddingLogs: Bool = oldGeometry.contentSize.height < newGeometry.contentSize.height
                        let isUpScrolling: Bool = oldGeometry.contentOffset.y > newGeometry.contentOffset.y
                        let bottomY = newGeometry.contentSize.height - newGeometry.bounds.height
                        let offsetY = newGeometry.contentOffset.y
                        if bottomY <= offsetY {
                            autoScroll = true
                        } else {
                            if isUpScrolling, autoScroll, bottomY > offsetY + 50 {
                                withAnimation {
                                    autoScroll = false
                                }
                            }
                        }

                        if isAddingLogs, autoScroll, let lastID = viewState.displayLogs.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastID)
                            }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if !autoScroll {
                            HStack {
                                Spacer()

                                BottomScrollButton {
                                    autoScroll = true
                                    guard let lastLogID = viewState.displayLogs.last?.id else {
                                        return
                                    }
                                    withAnimation {
                                        proxy.scrollTo(lastLogID)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
            }

            LogFilterView(filter: $viewState.filter, allTags: viewState.tags)
                .padding(.horizontal)

        }
        .background(
            Color(uiColor: .systemBackground)
                .opacity(viewState.isTransparent ? 0.5 : 1)
                .ignoresSafeArea()
        )
    }
}

extension LogView {
    @ViewBuilder
    var headerContent: some View {
        HStack {
            CloseButton {
                focus = false
                withAnimation {
                    dismiss()
                }
            }

            Picker("periods", selection: $viewState.selectedPeriod) {
                ForEach(Period.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)

            Menu {
                Toggle(isOn: $viewState.isTransparent) {
                    Text("背景を半透明にする")
                }
                .fixedSize()
                Button {
                    viewState.toggleActive()
                } label: {
                    Label(viewState.active ? "ログを一時停止" : "ログの再開", systemImage: viewState.active ? "pause.circle" : "play.circle")
                }
                Button(role: .destructive) {
                    viewState.deleteLogs()
                } label: {
                    Label("ログを削除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 15)
    }

    @ViewBuilder
    var listContent: some View {
        List {            switch viewState.selectedPeriod {
            case .all:
                ForEach(viewState.logs) { log in
                    LogRow(debugLog: log, tags: viewState.tags)
                        .listRowSeparator(.hidden)
                        .id(log.id)
                }
            case .file:
                ForEach(viewState.fileTags, id: \.self) { fileName in
                    Section(isExpanded: expandBinding(title: fileName, \.fileExpands)) {
                        ForEach(viewState.fileLogs(for: fileName)) { log in
                            LogRow(debugLog: log, tags: viewState.tags, isShowFilePath: false)
                                .listRowSeparator(.hidden)
                                .id(log.id)
                        }
                    } header: {
                        sectionHeader(title: fileName, \.fileExpands)
                    }
                    .textCase(.none)
                }
            case .function:
                ForEach(viewState.functionTags, id: \.self) { fileFunction in
                    Section(isExpanded: expandBinding(title: fileFunction, \.functionExpands)) {
                        ForEach(viewState.functionLogs(for: fileFunction)) { log in
                            LogRow(debugLog: log, tags: viewState.tags, isShowFilePath: false, isShowFunction: false)
                                .listRowSeparator(.hidden)
                                .id(log.id)
                        }
                    } header: {
                        sectionHeader(title: fileFunction, \.functionExpands)
                    }
                    .textCase(.none)
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(-10)
        .listSectionSpacing(-10)
        .scrollContentBackground(.hidden)
    }

    typealias Expands = ReferenceWritableKeyPath<LogViewState, String?>

    func expandBinding(title: String, _ expands: Expands) -> Binding<Bool> {
        .init(
            get: {
                viewState[keyPath: expands] == title
            },
            set: {
                if !$0 {
                    viewState[keyPath: expands] = nil
                }
            }
        )
    }

    @ViewBuilder
    func sectionHeader(title: String, _ expands: Expands) -> some View {
        let isOpen = viewState[keyPath: expands] == title
        Button {
            withAnimation {
                if isOpen {
                    viewState[keyPath: expands] = nil
                } else {
                    viewState[keyPath: expands] = title
                }
            }
        } label: {
            SectionHeader(title: title, isOpen: isOpen)
        }
    }
}

#Preview {
    @Previewable @State var visible: Bool = true
    LinearGradient(
        gradient: Gradient(colors: [.white,Color.blue,Color.red,.black]),
        startPoint: .init(x: 0, y: 0.4),    // start地点
        endPoint: .init(x: 0.55, y: 0.7)     // end地点
    )
    .overlay {
        Button("toggle") {
            visible.toggle()
        }
    }
    .ignoresSafeArea()
    .logViewer(on: .custom($visible))
    .task {
        for _ in 0..<500 {
            guard Logger.shared.active else { continue }
            let duration = if Bool.random() {
                (1...8).randomElement() ?? 1
            } else {
                (10...20).randomElement() ?? 10
            }
            try? await Task.sleep(for: .seconds(Double(duration) / 10))
            var count = 1
            Logger.shared.add(.random)
            if Bool.random() {
                Logger.shared.add(.random)
                count += 1
            }
            if Bool.random() {
                Logger.shared.add(.random)
                count += 1
            }
            if Bool.random() {
                Logger.shared.add(.random)
                count += 1
            }
            if Bool.random() {
                Logger.shared.add(.random)
                count += 1
            }
        }
    }
}
