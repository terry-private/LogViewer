import SwiftUI
import Testing
import UIKit
import LogViewerCore
@testable import LogViewerUI

@Suite("UIKit専用ウインドウ配線")
@MainActor
struct UIKitLogViewerWindowAdapterTests {
    private final class RecordingWindow: UIWindow {
        var makeKeyCallCount = 0
        var makeKeyAndVisibleCallCount = 0

        override func makeKey() {
            makeKeyCallCount += 1
        }

        override func makeKeyAndVisible() {
            makeKeyAndVisibleCallCount += 1
            isHidden = false
        }
    }

    @Test("LogViewをHostingControllerとして設定する")
    func installsHostingController() throws {
        let window = RecordingWindow(frame: .zero)
        let store = InMemoryLogStore()
        store.add(LogEntry(
            message: "injected",
            source: SourceLocation(
                fileID: "AdapterTests.swift",
                function: "installsHostingController()",
                line: 1
            )
        ))
        var didDismiss = false

        let hostingController = UIKitLogViewerWindowAdapter.installContent(
            on: window,
            store: store,
            isTransparent: true,
            dismiss: { didDismiss = true }
        )

        #expect(window.rootViewController === hostingController)
        #expect(hostingController.view.backgroundColor == .clear)
        #expect(hostingController.rootView.viewState.isBackgroundTransparent)
        #expect(
            hostingController.rootView.viewState.logs.map(\.message)
                == ["injected"]
        )

        hostingController.rootView.dismiss()
        #expect(didDismiss)
    }

    @Test("警告より上のレベルでキー表示する")
    func showsAboveAlertsAsKeyWindow() {
        let window = RecordingWindow(frame: .zero)
        window.isHidden = true
        let bounds = CGRect(x: 10, y: 20, width: 300, height: 500)

        UIKitLogViewerWindowAdapter.show(window, bounds: bounds)

        #expect(window.frame == bounds)
        #expect(window.backgroundColor == .clear)
        #expect(window.windowLevel == .alert + 1)
        #expect(window.makeKeyAndVisibleCallCount == 1)
        #expect(!window.isHidden)
    }

    @Test("閉じると非表示にしてRoot Controllerを解放する")
    func tearsDownWindowContent() {
        let window = RecordingWindow(frame: .zero)
        window.rootViewController = UIViewController()
        window.isHidden = false

        UIKitLogViewerWindowAdapter.tearDown(window)

        #expect(window.isHidden)
        #expect(window.rootViewController == nil)
    }

    @Test("元のウインドウへキー状態を戻す")
    func restoresKeyWindow() {
        let window = RecordingWindow(frame: .zero)

        UIKitLogViewerWindowAdapter.makeKey(window)

        #expect(window.makeKeyCallCount == 1)
    }

    @Test("SceneReaderの解体はnilを通知する")
    func sceneReaderDismantleReportsNil() {
        var reportedScene: UIWindowScene?
        var callbackCount = 0
        let view = LogViewerWindowSceneReader.SceneObservingView {
            callbackCount += 1
            reportedScene = $0
        }

        LogViewerWindowSceneReader.dismantleUIView(
            view,
            coordinator: ()
        )

        #expect(callbackCount == 1)
        #expect(reportedScene == nil)
    }

    @Test("SceneReaderの接続通知はUIView更新の次に送る")
    func sceneReaderReportsAfterMovingToWindow() async {
        let window = UIWindow(frame: .zero)

        await withCheckedContinuation { continuation in
            let view = LogViewerWindowSceneReader.SceneObservingView {
                #expect($0 == nil)
                continuation.resume()
            }
            window.addSubview(view)
        }
    }

    @Test("SceneReaderは解体後に保留中の接続通知を送らない")
    func sceneReaderCancelsPendingReportOnDismantle() async {
        var callbackCount = 0
        let view = LogViewerWindowSceneReader.SceneObservingView { _ in
            callbackCount += 1
        }
        let window = UIWindow(frame: .zero)

        window.addSubview(view)
        LogViewerWindowSceneReader.dismantleUIView(
            view,
            coordinator: ()
        )
        await Task.yield()
        await Task.yield()

        #expect(callbackCount == 1)
    }
}
