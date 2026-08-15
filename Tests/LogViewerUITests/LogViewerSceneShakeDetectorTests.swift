import Testing
import UIKit
@testable import LogViewerUI

@Suite("場面単位のシェイク検知")
@MainActor
struct LogViewerSceneShakeDetectorTests {
    private final class Scene {}

    private final class MotionRecordingView: UIView {
        private(set) var receivedMotions: [UIEvent.EventSubtype] = []

        override func motionEnded(
            _ motion: UIEvent.EventSubtype,
            with event: UIEvent?
        ) {
            receivedMotions.append(motion)
            super.motionEnded(motion, with: event)
        }
    }

    @Test("シェイクだけを所属場面へ転送する")
    func routesOnlyShakeToAttachedScene() {
        let router = ShakeEventRouter<Scene>()
        let firstScene = Scene()
        let secondScene = Scene()
        var receivedScenes: [Scene] = []

        router.receive(.motionShake, scene: firstScene) {
            receivedScenes.append($0)
        }
        router.receive(.remoteControlPlay, scene: secondScene) {
            receivedScenes.append($0)
        }
        router.receive(.motionShake, scene: nil) {
            receivedScenes.append($0)
        }

        #expect(receivedScenes.count == 1)
        #expect(receivedScenes.first === firstScene)
    }

    @Test("重複したシェイクでも表示状態を閉じない")
    func repeatedShakeKeepsViewerVisible() {
        let first = ShakePresentationReducer.visibility(
            afterShakeWhileVisible: false
        )
        let second = ShakePresentationReducer.visibility(
            afterShakeWhileVisible: first
        )

        #expect(first)
        #expect(second)
    }

    @Test("既存の入力先がある場合はFirst Responderを奪わない")
    func existingFirstResponderPreventsActivation() {
        #expect(ShakeResponderActivationPolicy.shouldActivate(
            isWindowKey: true,
            isDetectorFirstResponder: false,
            hasAnotherFirstResponder: false
        ))
        #expect(!ShakeResponderActivationPolicy.shouldActivate(
            isWindowKey: true,
            isDetectorFirstResponder: false,
            hasAnotherFirstResponder: true
        ))
        #expect(!ShakeResponderActivationPolicy.shouldActivate(
            isWindowKey: false,
            isDetectorFirstResponder: false,
            hasAnotherFirstResponder: false
        ))
    }

    @Test("検知Viewは操作とアクセシビリティを妨げない")
    func detectorViewDoesNotInterceptInteraction() {
        let view = LogViewerSceneShakeDetector.SceneShakeDetectingView { _ in }

        #expect(view.canBecomeFirstResponder)
        #expect(!view.isUserInteractionEnabled)
        #expect(!view.isAccessibilityElement)
        #expect(view.accessibilityElementsHidden)
    }

    @Test("シェイクを次のResponderへ伝播する")
    func shakeContinuesThroughResponderChain() {
        let parent = MotionRecordingView()
        let detector =
            LogViewerSceneShakeDetector.SceneShakeDetectingView { _ in }
        parent.addSubview(detector)

        detector.motionEnded(.motionShake, with: nil)

        #expect(parent.receivedMotions == [.motionShake])
    }

    @Test("通知payloadは従来のeventと追加の場面を保持する")
    func notificationPayloadPreservesEventObject() {
        let event = NSObject()
        let scene = Scene()
        let payload = ShakeNotificationPayload(event: event, scene: scene)

        #expect(payload.object as? NSObject === event)
        #expect(
            payload.userInfo[
                LogViewerShakeNotification.windowSceneUserInfoKey
            ] as? Scene === scene
        )
    }

    @Test("ウインドウ全階層から別のFirst Responderを探索する")
    func findsFirstResponderOutsideRootControllerView() {
        let window = UIWindow(frame: .zero)
        let rootView = UIView()
        let siblingContainer = UIView()
        let detector =
            LogViewerSceneShakeDetector.SceneShakeDetectingView { _ in }
        let textField = UITextField()
        window.addSubview(rootView)
        window.addSubview(siblingContainer)
        rootView.addSubview(detector)
        siblingContainer.addSubview(textField)

        #expect(window.containsFirstResponder(
            excluding: detector,
            where: { $0 === textField }
        ))
        #expect(!window.containsFirstResponder(
            excluding: detector,
            where: { $0 === detector }
        ))
    }

    @Test("解体時にウインドウ監視とFirst Responderを解除する")
    func dismantleStopsObservation() {
        let window = UIWindow(frame: .zero)
        let view = LogViewerSceneShakeDetector.SceneShakeDetectingView { _ in }
        window.addSubview(view)

        #expect(view.isObservingWindowState)

        LogViewerSceneShakeDetector.dismantleUIView(
            view,
            coordinator: ()
        )

        #expect(!view.isObservingWindowState)
        #expect(!view.isFirstResponder)
    }
}
