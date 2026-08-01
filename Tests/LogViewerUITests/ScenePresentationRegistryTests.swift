import Foundation
import Testing
@testable import LogViewerUI

@Suite("場面ごとの専用ウインドウ管理")
@MainActor
struct ScenePresentationRegistryTests {
    private final class Scene {}
    private final class Window {}

    @Test("同じ場面では1つだけ保持し別の場面は独立する")
    func keepsOneWindowPerScene() throws {
        let registry = ScenePresentationRegistry<Scene, Window>()
        let firstScene = Scene()
        let secondScene = Scene()
        let firstOwner = UUID()
        let secondOwner = UUID()

        let firstWindow = registry.claim(
            scene: firstScene,
            previousWindow: nil,
            ownerID: firstOwner,
            makeWindow: Window.init
        )
        let duplicateWindow = registry.claim(
            scene: firstScene,
            previousWindow: nil,
            ownerID: secondOwner,
            makeWindow: Window.init
        )
        let secondWindow = registry.claim(
            scene: secondScene,
            previousWindow: nil,
            ownerID: secondOwner,
            makeWindow: Window.init
        )

        #expect(firstWindow != nil)
        #expect(duplicateWindow == nil)
        #expect(secondWindow != nil)
        #expect(registry.count == 2)
        #expect(registry.isOwned(scene: firstScene, ownerID: firstOwner))
        #expect(!registry.isOwned(scene: firstScene, ownerID: secondOwner))
    }

    @Test("所有者だけが解放でき元のウインドウを返す")
    func onlyOwnerCanReleaseAndRestorePreviousWindow() throws {
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let previousWindow = Window()
        let owner = UUID()
        let anotherOwner = UUID()
        let presentedWindow = try #require(registry.claim(
            scene: scene,
            previousWindow: previousWindow,
            ownerID: owner,
            makeWindow: Window.init
        ))

        #expect(
            registry.release(scene: scene, ownerID: anotherOwner) == nil
        )
        #expect(registry.count == 1)

        let released = try #require(
            registry.release(scene: scene, ownerID: owner)
        )

        #expect(released.window === presentedWindow)
        #expect(released.previousWindow === previousWindow)
        #expect(registry.count == 0)
    }

    @Test("解放後は表示ウインドウを保持し続けない")
    func releaseBreaksWindowRetention() throws {
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let owner = UUID()
        var window: Window? = Window()
        weak let weakWindow = window

        _ = registry.claim(
            scene: scene,
            previousWindow: nil,
            ownerID: owner,
            makeWindow: { window! }
        )
        window = nil

        #expect(weakWindow != nil)
        var released = registry.release(scene: scene, ownerID: owner)
        #expect(released?.window === weakWindow)
        released = nil
        #expect(weakWindow == nil)
    }
}

@Suite("専用ウインドウ表示制御")
@MainActor
struct SceneWindowPresentationControllerTests {
    private final class Scene {
        var windows: [Window] = []
    }

    private final class Window {
        weak var scene: Scene?
        var isKey = false
        var isHidden = false
        var hasContent = false
        var dismissAction: (() -> Void)?
    }

    private final class Recorder {
        var actions: [String] = []
    }

    @Test("表示内容を設定してキーウインドウとして前面へ出す")
    func installsContentAndShowsKeyWindow() throws {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let previousWindow = Window()
        previousWindow.scene = scene
        previousWindow.isKey = true
        scene.windows = [previousWindow]
        let controller = makeController(
            registry: registry,
            recorder: recorder
        )

        let didPresent = controller.present(
            in: scene,
            installContent: { window, dismiss in
                window.hasContent = true
                window.dismissAction = dismiss
                recorder.actions.append("content")
            },
            onDismiss: {}
        )

        #expect(didPresent)
        #expect(scene.windows.count == 2)
        let presentedWindow = try #require(scene.windows.last)
        #expect(presentedWindow.scene === scene)
        #expect(presentedWindow.hasContent)
        #expect(presentedWindow.isKey)
        #expect(!previousWindow.isKey)
        #expect(recorder.actions == ["make", "content", "show"])
    }

    @Test("同じ場面への連続表示と別所有者の競合で重複しない")
    func repeatedPresentationDoesNotDuplicateWindow() {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let first = makeController(
            registry: registry,
            recorder: recorder
        )
        let second = makeController(
            registry: registry,
            recorder: recorder
        )

        let firstResult = first.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )
        let repeatedResult = first.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )
        let competingResult = second.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )

        #expect(firstResult)
        #expect(repeatedResult)
        #expect(!competingResult)
        #expect(scene.windows.count == 1)
        #expect(registry.count == 1)
        #expect(recorder.actions.filter { $0 == "show" }.count == 1)
    }

    @Test("閉じる直前までキーなら元のウインドウを復元する")
    func dismissRestoresPreviousKeyWindow() throws {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let previousWindow = Window()
        previousWindow.scene = scene
        previousWindow.isKey = true
        scene.windows = [previousWindow]
        let controller = makeController(
            registry: registry,
            recorder: recorder
        )
        var didDismiss = false
        _ = controller.present(
            in: scene,
            installContent: installContent,
            onDismiss: { didDismiss = true }
        )
        let presentedWindow = try #require(scene.windows.last)

        presentedWindow.dismissAction?()

        #expect(didDismiss)
        #expect(presentedWindow.isHidden)
        #expect(!presentedWindow.hasContent)
        #expect(previousWindow.isKey)
        #expect(registry.count == 0)
        #expect(recorder.actions.suffix(2) == ["tearDown", "makeKey"])
    }

    @Test("表示中に別ウインドウがキーになった場合は奪い返さない")
    func dismissPreservesNewerKeyWindow() throws {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let previousWindow = Window()
        previousWindow.scene = scene
        previousWindow.isKey = true
        scene.windows = [previousWindow]
        let controller = makeController(
            registry: registry,
            recorder: recorder
        )
        _ = controller.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )
        let presentedWindow = try #require(scene.windows.last)
        let newerWindow = Window()
        newerWindow.scene = scene
        scene.windows.append(newerWindow)
        makeKey(newerWindow, in: scene)

        controller.dismiss()

        #expect(presentedWindow.isHidden)
        #expect(newerWindow.isKey)
        #expect(!previousWindow.isKey)
        #expect(!recorder.actions.suffix(1).contains("makeKey"))
    }

    @Test("元のウインドウを戻せない場合は同じ場面の代替へ戻す")
    func dismissUsesVisibleFallbackWindow() throws {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        let previousWindow = Window()
        previousWindow.scene = scene
        previousWindow.isKey = true
        let fallbackWindow = Window()
        fallbackWindow.scene = scene
        scene.windows = [previousWindow, fallbackWindow]
        let controller = makeController(
            registry: registry,
            recorder: recorder
        )
        _ = controller.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )
        previousWindow.isHidden = true

        controller.dismiss()

        #expect(fallbackWindow.isKey)
    }

    @Test("場面を移ると古い表示を解放して新しい場面へ表示する")
    func movingScenesReleasesOldWindow() throws {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let firstScene = Scene()
        let secondScene = Scene()
        let controller = makeController(
            registry: registry,
            recorder: recorder
        )
        _ = controller.present(
            in: firstScene,
            installContent: installContent,
            onDismiss: {}
        )
        let firstWindow = try #require(firstScene.windows.last)

        let didPresent = controller.present(
            in: secondScene,
            installContent: installContent,
            onDismiss: {}
        )

        #expect(didPresent)
        #expect(firstWindow.isHidden)
        #expect(!firstWindow.hasContent)
        #expect(secondScene.windows.last?.isKey == true)
        #expect(registry.count == 1)
    }

    @Test("表示制御の解放時にウインドウと内容を解放する")
    func controllerDeinitReleasesPresentedWindow() {
        let recorder = Recorder()
        let registry = ScenePresentationRegistry<Scene, Window>()
        let scene = Scene()
        var controller: SceneWindowPresentationController<Scene, Window>? =
            makeController(registry: registry, recorder: recorder)
        _ = controller?.present(
            in: scene,
            installContent: installContent,
            onDismiss: {}
        )
        weak let weakWindow = scene.windows.last
        scene.windows.removeAll()

        controller = nil

        #expect(registry.count == 0)
        #expect(weakWindow == nil)
    }

    private func makeController(
        registry: ScenePresentationRegistry<Scene, Window>,
        recorder: Recorder
    ) -> SceneWindowPresentationController<Scene, Window> {
        SceneWindowPresentationController(
            registry: registry,
            environment: SceneWindowPresentationEnvironment(
                keyWindow: { scene in
                    scene.windows.first(where: \.isKey)
                },
                makeWindow: { scene in
                    let window = Window()
                    window.scene = scene
                    scene.windows.append(window)
                    recorder.actions.append("make")
                    return window
                },
                isKeyWindow: \.isKey,
                canRestore: { window, scene in
                    window.scene === scene && !window.isHidden
                },
                fallbackWindow: { scene, presentedWindow in
                    scene.windows.first {
                        $0 !== presentedWindow && !$0.isHidden
                    }
                },
                show: { window, scene in
                    makeKey(window, in: scene)
                    recorder.actions.append("show")
                },
                tearDown: { window in
                    window.isHidden = true
                    window.hasContent = false
                    window.dismissAction = nil
                    recorder.actions.append("tearDown")
                },
                makeKey: { window in
                    if let scene = window.scene {
                        makeKey(window, in: scene)
                    }
                    recorder.actions.append("makeKey")
                }
            )
        )
    }

    private func installContent(
        window: Window,
        dismiss: @escaping @MainActor () -> Void
    ) {
        window.hasContent = true
        window.dismissAction = dismiss
    }

    private func makeKey(_ window: Window, in scene: Scene) {
        for candidate in scene.windows {
            candidate.isKey = candidate === window
        }
    }
}
