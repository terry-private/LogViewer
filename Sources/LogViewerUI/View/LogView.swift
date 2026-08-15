import LogViewerCore
import Observation
import SwiftUI
import UIKit

internal struct LogView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State var viewState: LogViewState = .init()
    @FocusState var focus: Bool
    @AccessibilityFocusState private var closeButtonFocused: Bool
    @State var autoScroll: Bool = true
    @State private var deletionConfirmation =
        LogDeletionConfirmationState()
    @State private var shareItem: LogShareItem?
    @State private var temporaryExportURL: URL?
    @State private var isExportErrorPresented = false
    let dismiss: () -> Void

    init(
        store: any LogStore = Logger.shared.store,
        privacyPolicy: LogPrivacyPolicy = .none,
        isTransparent: Bool = false,
        dismiss: @escaping () -> Void
    ) {
        _viewState = State(
            initialValue: LogViewState(
                store: store,
                privacyPolicy: privacyPolicy,
                isBackgroundTransparent: isTransparent
            )
        )
        self.dismiss = dismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            headerContent

            if !viewState.active {
                Label(
                    LogViewerLocalization.string(.recordingPaused),
                    systemImage: "pause.circle.fill"
                )
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.18))
                .accessibilityAddTraits(.isStaticText)
            }

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

            LogFilterView(
                filter: $viewState.filter,
                allTags: viewState.tags,
                resultCount: viewState.resultCount,
                totalCount: viewState.totalCount
            )
                .padding(.horizontal)

        }
        .background(
            Color(uiColor: .systemBackground)
                .opacity(viewState.isBackgroundTransparent ? 0.5 : 1)
                .ignoresSafeArea()
        )
        .task {
            await viewState.observeStore()
        }
        .task(id: viewState.periodScheduleRevision) {
            await viewState.waitForNextRelativePeriodTransition()
        }
        .task {
            await Task.yield()
            if LogViewerAccessibilityPolicy.initialFocusTarget == .close {
                closeButtonFocused = true
            }
        }
        .confirmationDialog(
            LogViewerLocalization.string(.logsDeleteTitle),
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button(
                LogViewerLocalization.string(.logsDeleteAction),
                role: .destructive
            ) {
                if deletionConfirmation.confirm() {
                    viewState.deleteLogs()
                }
            }
            Button(
                LogViewerLocalization.string(.commonCancel),
                role: .cancel
            ) {
                deletionConfirmation.cancel()
            }
        } message: {
            Text(LogViewerLocalization.string(.logsDeleteMessage))
        }
        .sheet(item: $shareItem, onDismiss: removeTemporaryExport) { item in
            LogShareSheet(activityItems: [item.activityItem])
        }
        .alert(
            LogViewerLocalization.string(.logsExportErrorTitle),
            isPresented: $isExportErrorPresented
        ) {
            Button(LogViewerLocalization.string(.commonOK)) {}
        } message: {
            Text(LogViewerLocalization.string(.logsExportErrorMessage))
        }
        .onDisappear {
            removeTemporaryExport()
        }
    }
}

extension LogView {
    @ViewBuilder
    var headerContent: some View {
        if LogViewerAccessibilityPolicy.adaptiveLayout(
            for: dynamicTypeSize
        ).usesStackedHeader {
            VStack(spacing: 8) {
                HStack {
                    closeControl
                    Spacer()
                    actionMenu
                }
                groupingMenu
            }
            .padding(.horizontal, 15)
        } else {
            HStack {
                closeControl
                groupingPicker
                actionMenu
            }
            .padding(.horizontal, 15)
        }
    }

    private var closeControl: some View {
        CloseButton {
            focus = false
            withAnimation {
                dismiss()
            }
        }
        .accessibilityFocused($closeButtonFocused)
    }

    private var groupingPicker: some View {
        Picker(
            LogViewerLocalization.string(.groupingLabel),
            selection: $viewState.selectedPeriod
        ) {
            ForEach(Period.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var groupingMenu: some View {
        Picker(
            LogViewerLocalization.string(.groupingLabel),
            selection: $viewState.selectedPeriod
        ) {
            ForEach(Period.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionMenu: some View {
        Menu {
            Toggle(isOn: $viewState.isBackgroundTransparent) {
                Text(LogViewerLocalization.string(
                    .settingsTransparentBackground
                ))
            }
            Button {
                viewState.toggleActive()
            } label: {
                Label(
                    LogViewerLocalization.string(
                        LogViewerAccessibilityPolicy.recordingActionKey(
                            isRecordingEnabled: viewState.active
                        )
                    ),
                    systemImage: viewState.active
                        ? "pause.circle"
                        : "play.circle"
                )
            }
            Button {
                UIPasteboard.general.string = try? viewState.exportString(
                    format: .plainText
                )
            } label: {
                Label(
                    LogViewerLocalization.string(.logsCopyFiltered),
                    systemImage: "doc.on.doc"
                )
            }
            Button {
                prepareShare(format: .plainText)
            } label: {
                Label(
                    LogViewerLocalization.string(.logsShareText),
                    systemImage: "square.and.arrow.up"
                )
            }
            Button {
                prepareShare(format: .json)
            } label: {
                Label(
                    LogViewerLocalization.string(.logsShareJSON),
                    systemImage: "curlybraces"
                )
            }
            Button(role: .destructive) {
                deletionConfirmation.request()
            } label: {
                Label(
                    LogViewerLocalization.string(.logsDeleteAction),
                    systemImage: "trash"
                )
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .accessibilityLabel(
                    LogViewerLocalization.string(
                        .accessibilityMoreActions
                    )
                )
        }
    }

    private var emptyState: some View {
        let key = LogViewerAccessibilityPolicy.emptyStateKey(
            resultCount: viewState.resultCount,
            totalCount: viewState.totalCount,
            isFilterActive: viewState.filter.isActive
        ) ?? .emptyNoLogs
        return VStack(spacing: 8) {
            Image(systemName: viewState.filter.isActive
                ? "line.3.horizontal.decrease.circle"
                : "doc.text.magnifyingglass")
                .font(.title2)
                .accessibilityHidden(true)
            Text(LogViewerLocalization.string(key))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .padding()
        .accessibilityElement(children: .combine)
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { deletionConfirmation.isPresented },
            set: { isPresented in
                if !isPresented {
                    deletionConfirmation.cancel()
                }
            }
        )
    }

    private func prepareShare(format: LogExportFormat) {
        do {
            switch format {
            case .plainText:
                shareItem = LogShareItem(
                    activityItem: try viewState.exportString(
                        format: .plainText
                    )
                )
            case .json:
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("LogViewer-\(UUID()).json")
                try viewState.exportData(format: .json).write(
                    to: url,
                    options: .atomic
                )
                temporaryExportURL = url
                shareItem = LogShareItem(
                    activityItem: url
                )
            }
        } catch {
            isExportErrorPresented = true
        }
    }

    private func removeTemporaryExport() {
        guard let url = temporaryExportURL else { return }
        try? FileManager.default.removeItem(at: url)
        temporaryExportURL = nil
    }

    @ViewBuilder
    var listContent: some View {
        List {
            switch viewState.selectedPeriod {
            case .all:
                ForEach(viewState.logs) { log in
                    LogRow(debugLog: log)
                        .listRowSeparator(.hidden)
                        .id(log.id)
                }
            case .file:
                ForEach(viewState.fileTags, id: \.self) { fileName in
                    Section(isExpanded: expandBinding(title: fileName, \.fileExpands)) {
                        ForEach(viewState.fileLogs(for: fileName)) { log in
                            LogRow(debugLog: log, isShowFilePath: false)
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
                            LogRow(debugLog: log, isShowFilePath: false, isShowFunction: false)
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
        .overlay {
            if LogViewerAccessibilityPolicy.emptyStateKey(
                resultCount: viewState.resultCount,
                totalCount: viewState.totalCount,
                isFilterActive: viewState.filter.isActive
            ) != nil {
                emptyState
            }
        }
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

private struct LogShareItem: Identifiable {
    let id = UUID()
    let activityItem: Any

    init(activityItem: Any) {
        self.activityItem = activityItem
    }
}

private struct LogShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

#if DEBUG
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
            guard Logger.shared.store.snapshot().isRecordingEnabled else {
                continue
            }
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
                Logger.shared.add(
                    LogEntry(
                        message: "test message",
                        source: .init(
                            fileID: "test.swift",
                            function: "test()"
                        ),
                        tags: ["a", "ab", "abc", "abcde", "abcdefg", "abdcdefghijklmnopqrs"]
                    )
                )
                count += 1
            }
            if Bool.random() {
                Logger.shared.add(
                    LogEntry(
                        message: "test message",
                        source: .init(
                            fileID: "test.swift",
                            function: "test()"
                        ),
                        tags: ["a", "ab", "abc", "abcde", "abcdefg", "abdcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijkl"]
                    )
                )
                count += 1
            }
        }
    }
}
#endif
