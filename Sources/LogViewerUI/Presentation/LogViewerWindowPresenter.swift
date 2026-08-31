import LogViewerCore
import SwiftUI
import UIKit

@MainActor
final class ScenePresentationRegistry<Scene: AnyObject, Window: AnyObject> {
    final class Entry {
        weak var scene: Scene?
        let window: Window
        weak var previousWindow: Window?
        let ownerID: UUID

        init(
            scene: Scene,
            window: Window,
            previousWindow: Window?,
            ownerID: UUID
        ) {
            self.scene = scene
            self.window = window
            self.previousWindow = previousWindow
            self.ownerID = ownerID
        }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    var count: Int {
        entries.count
    }

    func claim(
        scene: Scene,
        previousWindow: Window?,
        ownerID: UUID,
        makeWindow: () -> Window
    ) -> Window? {
        removeEntriesWithoutScene()
        let key = ObjectIdentifier(scene)
        guard entries[key] == nil else { return nil }

        let window = makeWindow()
        entries[key] = Entry(
            scene: scene,
            window: window,
            previousWindow: previousWindow,
            ownerID: ownerID
        )
        return window
    }

    func isOwned(scene: Scene, ownerID: UUID) -> Bool {
        entries[ObjectIdentifier(scene)]?.ownerID == ownerID
    }

    func release(
        scene: Scene,
        ownerID: UUID
    ) -> (window: Window, previousWindow: Window?)? {
        let key = ObjectIdentifier(scene)
        guard let entry = entries[key], entry.ownerID == ownerID else {
            return nil
        }
        entries[key] = nil
        return (entry.window, entry.previousWindow)
    }

    private func removeEntriesWithoutScene() {
        entries = entries.filter { $0.value.scene != nil }
    }
}

@MainActor
struct SceneWindowPresentationEnvironment<Scene: AnyObject, Window: AnyObject> {
    let keyWindow: (Scene) -> Window?
    let makeWindow: (Scene) -> Window
    let isKeyWindow: (Window) -> Bool
    let canRestore: (Window, Scene) -> Bool
    let fallbackWindow: (Scene, Window) -> Window?
    let show: (Window, Scene) -> Void
    let tearDown: (Window) -> Void
    let makeKey: (Window) -> Void
}

@MainActor
final class SceneWindowPresentationController<Scene: AnyObject, Window: AnyObject> {
    private let registry: ScenePresentationRegistry<Scene, Window>
    private let environment: SceneWindowPresentationEnvironment<Scene, Window>
    private let ownerID = UUID()
    private var presentedScene: Scene?

    init(
        registry: ScenePresentationRegistry<Scene, Window>,
        environment: SceneWindowPresentationEnvironment<Scene, Window>
    ) {
        self.registry = registry
        self.environment = environment
    }

    @discardableResult
    func present(
        in scene: Scene,
        installContent: (
            Window,
            @escaping @MainActor () -> Void
        ) -> Void,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Bool {
        if presentedScene === scene,
           registry.isOwned(scene: scene, ownerID: ownerID) {
            return true
        }

        dismiss()

        guard let window = registry.claim(
            scene: scene,
            previousWindow: environment.keyWindow(scene),
            ownerID: ownerID,
            makeWindow: { environment.makeWindow(scene) }
        ) else {
            return false
        }

        presentedScene = scene
        installContent(window) { [weak self] in
            self?.dismiss()
            onDismiss()
        }
        environment.show(window, scene)
        return true
    }

    func dismiss() {
        guard let scene = presentedScene else { return }
        presentedScene = nil
        guard let released = registry.release(
            scene: scene,
            ownerID: ownerID
        ) else {
            return
        }

        let shouldRestoreKeyWindow = environment.isKeyWindow(
            released.window
        )
        environment.tearDown(released.window)
        guard shouldRestoreKeyWindow else { return }

        if let previousWindow = released.previousWindow,
           environment.canRestore(previousWindow, scene) {
            environment.makeKey(previousWindow)
            return
        }

        if let fallbackWindow = environment.fallbackWindow(
            scene,
            released.window
        ) {
            environment.makeKey(fallbackWindow)
        }
    }

    isolated deinit {
        dismiss()
    }
}

@MainActor
final class LogViewerWindowPresenter {
    private static let registry = ScenePresentationRegistry<
        UIWindowScene,
        UIWindow
    >()
    private static let environment = SceneWindowPresentationEnvironment<
        UIWindowScene,
        UIWindow
    >(
        keyWindow: { scene in
            scene.windows.first(where: \.isKeyWindow)
                ?? scene.windows.first {
                    !$0.isHidden && $0.windowLevel == .normal
                }
        },
        makeWindow: { scene in
            UIWindow(windowScene: scene)
        },
        isKeyWindow: \.isKeyWindow,
        canRestore: { window, scene in
            window.windowScene === scene && !window.isHidden
        },
        fallbackWindow: { scene, presentedWindow in
            scene.windows.first {
                $0 !== presentedWindow
                    && !$0.isHidden
                    && $0.windowLevel == .normal
            }
        },
        show: { window, scene in
            UIKitLogViewerWindowAdapter.show(
                window,
                bounds: scene.coordinateSpace.bounds
            )
        },
        tearDown: { window in
            UIKitLogViewerWindowAdapter.tearDown(window)
        },
        makeKey: { window in
            UIKitLogViewerWindowAdapter.makeKey(window)
        }
    )

    private lazy var controller = SceneWindowPresentationController(
        registry: Self.registry,
        environment: Self.environment
    )

    @discardableResult
    func present(
        in scene: UIWindowScene,
        store: any LogStore,
        privacyPolicy: LogPrivacyPolicy = .none,
        isTransparent: Bool,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Bool {
        controller.present(
            in: scene,
            installContent: { window, dismiss in
                UIKitLogViewerWindowAdapter.installContent(
                    on: window,
                    store: store,
                    privacyPolicy: privacyPolicy,
                    isTransparent: isTransparent,
                    dismiss: dismiss
                )
            },
            onDismiss: onDismiss
        )
    }

    func dismiss() {
        controller.dismiss()
    }
}

@MainActor
enum UIKitLogViewerWindowAdapter {
    @discardableResult
    static func installContent(
        on window: UIWindow,
        store: any LogStore,
        privacyPolicy: LogPrivacyPolicy = .none,
        isTransparent: Bool,
        dismiss: @escaping @MainActor () -> Void
    ) -> UIHostingController<LogView> {
        let hostingController = UIHostingController(
            rootView: LogView(
                store: store,
                privacyPolicy: privacyPolicy,
                isTransparent: isTransparent,
                dismiss: dismiss
            )
        )
        hostingController.view.backgroundColor = .clear
        window.rootViewController = hostingController
        return hostingController
    }

    static func show(_ window: UIWindow, bounds: CGRect) {
        window.frame = bounds
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()
    }

    static func tearDown(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
    }

    static func makeKey(_ window: UIWindow) {
        window.makeKey()
    }
}

struct LogViewerWindowSceneReader: UIViewRepresentable {
    let onChange: @MainActor (UIWindowScene?) -> Void

    func makeUIView(context: Context) -> SceneObservingView {
        SceneObservingView(onChange: onChange)
    }

    func updateUIView(
        _ uiView: SceneObservingView,
        context: Context
    ) {
        uiView.onChange = onChange
    }

    static func dismantleUIView(
        _ uiView: SceneObservingView,
        coordinator: Void
    ) {
        uiView.cancelPendingReport()
        uiView.onChange(nil)
    }

    final class SceneObservingView: UIView {
        var onChange: @MainActor (UIWindowScene?) -> Void
        private var pendingReport: Task<Void, Never>?

        init(onChange: @escaping @MainActor (UIWindowScene?) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isHidden = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            pendingReport?.cancel()
            pendingReport = Task { @MainActor [weak self] in
                // SwiftUIのUIView更新中に@Stateを書き換えないよう、
                // Scene通知を次のMainActor実行機会へ送る。
                await Task.yield()
                guard !Task.isCancelled, let self else { return }
                onChange(window?.windowScene)
                pendingReport = nil
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
