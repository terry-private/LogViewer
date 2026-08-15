import SwiftUI
import UIKit

@MainActor
enum ShakePresentationReducer {
    static func visibility(
        afterShakeWhileVisible isVisible: Bool
    ) -> Bool {
        true
    }
}

@MainActor
enum ShakeResponderActivationPolicy {
    static func shouldActivate(
        isWindowKey: Bool,
        isDetectorFirstResponder: Bool,
        hasAnotherFirstResponder: Bool
    ) -> Bool {
        isWindowKey
            && !isDetectorFirstResponder
            && !hasAnotherFirstResponder
    }
}

struct ShakeNotificationPayload {
    let object: Any?
    let userInfo: [AnyHashable: Any]

    init<Scene: AnyObject>(event: Any?, scene: Scene) {
        object = event
        userInfo = [
            LogViewerShakeNotification.windowSceneUserInfoKey: scene,
        ]
    }
}

@MainActor
final class ShakeEventRouter<Scene: AnyObject> {
    func receive(
        _ motion: UIEvent.EventSubtype,
        scene: Scene?,
        onShake: (Scene) -> Void
    ) {
        guard motion == .motionShake, let scene else { return }
        onShake(scene)
    }
}

@MainActor
struct LogViewerSceneShakeDetector: UIViewRepresentable {
    let onShake: @MainActor (UIWindowScene) -> Void

    func makeUIView(context: Context) -> SceneShakeDetectingView {
        SceneShakeDetectingView(onShake: onShake)
    }

    func updateUIView(
        _ uiView: SceneShakeDetectingView,
        context: Context
    ) {
        uiView.onShake = onShake
    }

    static func dismantleUIView(
        _ uiView: SceneShakeDetectingView,
        coordinator: Void
    ) {
        uiView.stopObservingWindowState()
        uiView.resignFirstResponder()
    }

    final class SceneShakeDetectingView: UIView {
        var onShake: @MainActor (UIWindowScene) -> Void
        private let router = ShakeEventRouter<UIWindowScene>()
        private(set) var isObservingWindowState = false

        override var canBecomeFirstResponder: Bool {
            true
        }

        init(onShake: @escaping @MainActor (UIWindowScene) -> Void) {
            self.onShake = onShake
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
            accessibilityElementsHidden = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else {
                stopObservingWindowState()
                resignFirstResponder()
                return
            }

            startObservingWindowState()
            activateIfPossible()
        }

        override func motionEnded(
            _ motion: UIEvent.EventSubtype,
            with event: UIEvent?
        ) {
            let scene = window?.windowScene
            super.motionEnded(motion, with: event)
            router.receive(
                motion,
                scene: scene
            ) { [onShake] scene in
                let payload = ShakeNotificationPayload(
                    event: event,
                    scene: scene
                )
                NotificationCenter.default.post(
                    name: .deviceDidShakeNotification,
                    object: payload.object,
                    userInfo: payload.userInfo
                )
                onShake(scene)
            }
        }

        func activateIfPossible() {
            guard let window else { return }
            guard ShakeResponderActivationPolicy.shouldActivate(
                isWindowKey: window.isKeyWindow,
                isDetectorFirstResponder: isFirstResponder,
                hasAnotherFirstResponder: window.containsFirstResponder(
                    excluding: self
                )
            ) else {
                return
            }
            becomeFirstResponder()
        }

        func stopObservingWindowState() {
            guard isObservingWindowState else { return }
            NotificationCenter.default.removeObserver(self)
            isObservingWindowState = false
        }

        private func startObservingWindowState() {
            guard !isObservingWindowState else { return }
            isObservingWindowState = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidBecomeKey(_:)),
                name: UIWindow.didBecomeKeyNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidHide(_:)),
                name: UIResponder.keyboardDidHideNotification,
                object: nil
            )
        }

        @objc
        private func windowDidBecomeKey(_ notification: Notification) {
            guard notification.object as? UIWindow === window else { return }
            activateIfPossible()
        }

        @objc
        private func keyboardDidHide(_ notification: Notification) {
            activateIfPossible()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

extension UIView {
    func containsFirstResponder(
        excluding excludedView: UIView,
        where isFirstResponder: (UIView) -> Bool = { $0.isFirstResponder }
    ) -> Bool {
        if self !== excludedView, isFirstResponder(self) {
            return true
        }
        return subviews.contains {
            $0.containsFirstResponder(
                excluding: excludedView,
                where: isFirstResponder
            )
        }
    }
}

/// `deviceDidShakeNotification`に追加される場面情報。
public enum LogViewerShakeNotification {
    /// シェイクを受け取った`UIWindowScene`を取得する`userInfo`キー。
    public static let windowSceneUserInfoKey =
        "LogViewerWindowScene"
}

public extension NSNotification.Name {
    /// LogViewerの場面内Responderがシェイクを受け取った時に通知する。
    /// `object`は互換性のため従来どおり`UIEvent?`を使用し、場面は
    /// `LogViewerShakeNotification.windowSceneUserInfoKey`で取得できる。
    static let deviceDidShakeNotification = NSNotification.Name(
        "DeviceDidShakeNotification"
    )
}
