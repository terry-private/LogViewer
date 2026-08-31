import LogViewer
import SwiftUI
import UIKit

struct SampleSceneView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var model: SampleSceneModel
    @State private var windowScene: UIWindowScene?

    init(sceneName: String) {
        _model = State(initialValue: SampleSceneModel(sceneName: sceneName))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(SampleText.title)
                        .font(.title.bold())
                    Text("\(SampleText.scene): \(model.sceneName)")
                        .accessibilityIdentifier("sample.scene.name")
                    Text("\(SampleText.sceneShakeCount): \(model.sceneShakeCount)")
                        .accessibilityIdentifier("sample.shake.count")

                    TextField(SampleText.hostInput, text: $model.hostInput)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("sample.host.input")

                    Button(SampleText.showLogs) {
                        model.showLogs = true
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("sample.show.logs")

                    scenarioButtons

                    Button(SampleText.openSecondScene) {
                        openWindow(id: "secondary")
                    }
                    .accessibilityIdentifier("sample.open.secondary")

                    Button(SampleText.inspectClipboard) {
                        model.inspectClipboard()
                    }
                    .accessibilityIdentifier("sample.inspect.clipboard")

                    Text(model.clipboardPreview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .accessibilityIdentifier("sample.clipboard.preview")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("LogViewer")
        }
        .background {
            SampleWindowSceneReader { windowScene = $0 }
                .frame(width: 0, height: 0)
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .deviceDidShakeNotification
            )
        ) { notification in
            let shakenScene = notification.userInfo?[
                LogViewerShakeNotification.windowSceneUserInfoKey
            ] as? UIWindowScene
            if shakenScene === windowScene {
                model.sceneShakeCount += 1
            }
        }
        .sheet(isPresented: $model.showSheet) {
            scenarioContent(kind: .sheet)
        }
        .fullScreenCover(isPresented: $model.showFullScreen) {
            scenarioContent(kind: .fullScreen)
        }
        .alert(
            SampleText.alertTitle,
            isPresented: $model.showAlert
        ) {
            Button(SampleText.close, role: .cancel) {}
        }
        .logViewer(
            on: .custom($model.showLogs),
            presentation: .window,
            store: model.store
        )
        .logViewer(
            on: .shake,
            presentation: .window,
            store: model.store
        )
    }

    private var scenarioButtons: some View {
        Group {
            Button(SampleText.showSheet) {
                model.showSheet = true
            }
            .accessibilityIdentifier("sample.show.sheet")

            Button(SampleText.showFullScreen) {
                model.showFullScreen = true
            }
            .accessibilityIdentifier("sample.show.full-screen")

            Button(SampleText.showAlert) {
                model.showAlert = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    if model.showAlert {
                        model.showLogs = true
                    }
                }
            }
            .accessibilityIdentifier("sample.show.alert")
        }
    }

    private enum ScenarioKind {
        case sheet
        case fullScreen
    }

    private func scenarioContent(kind: ScenarioKind) -> some View {
        VStack(spacing: 20) {
            Text(kind == .sheet
                ? SampleText.sheetTitle
                : SampleText.fullScreenTitle)
                .font(.title2.bold())
                .accessibilityIdentifier("sample.scenario.title")
            TextField(SampleText.hostInput, text: $model.hostInput)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("sample.scenario.input")
            Button(SampleText.showLogs) {
                model.showLogs = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("sample.scenario.show-logs")
            Button(SampleText.close) {
                switch kind {
                case .sheet:
                    model.showSheet = false
                case .fullScreen:
                    model.showFullScreen = false
                }
            }
            .accessibilityIdentifier("sample.scenario.close")
        }
        .padding()
    }
}

private struct SampleWindowSceneReader: UIViewRepresentable {
    let update: @MainActor (UIWindowScene?) -> Void

    func makeUIView(context: Context) -> SceneView {
        let view = SceneView()
        view.update = update
        return view
    }

    func updateUIView(_ uiView: SceneView, context: Context) {
        uiView.update = update
        uiView.reportIfChanged()
    }

    static func dismantleUIView(_ uiView: SceneView, coordinator: ()) {
        uiView.cancelPendingReport()
        let update = uiView.update
        Task { @MainActor in
            await Task.yield()
            update?(nil)
        }
    }

    final class SceneView: UIView {
        var update: (@MainActor (UIWindowScene?) -> Void)?
        private weak var lastReportedScene: UIWindowScene?
        private var hasReported = false
        private var pendingReport: Task<Void, Never>?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportIfChanged()
        }

        func reportIfChanged() {
            let scene = window?.windowScene
            guard !hasReported || lastReportedScene !== scene else { return }
            hasReported = true
            lastReportedScene = scene
            let update = update
            pendingReport?.cancel()
            pendingReport = Task { @MainActor [weak self] in
                await Task.yield()
                guard !Task.isCancelled else { return }
                update?(scene)
                self?.pendingReport = nil
            }
        }

        func cancelPendingReport() {
            pendingReport?.cancel()
            pendingReport = nil
        }

        deinit {
            pendingReport?.cancel()
        }
    }
}
