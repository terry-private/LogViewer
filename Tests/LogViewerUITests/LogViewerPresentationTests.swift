import SwiftUI
import Testing
import LogViewerCore
@testable import LogViewerUI

@Suite("LogViewer presentation")
@MainActor
struct LogViewerPresentationTests {
    @Test(
        "custom trigger forwards transparency through its modifier",
        arguments: [false, true]
    )
    func customTriggerForwardsTransparency(isTransparent: Bool) {
        let view = Color.clear.logViewer(
            on: .custom(.constant(false)),
            isTransparent: isTransparent
        )

        let modifier = findValue(
            of: CustomLogViewModifier.self,
            in: view
        )

        let logView = modifier?.makeLogView {}

        #expect(modifier?.isTransparent == isTransparent)
        #expect(modifier?.presentation == .overlay)
        #expect(
            logView?.viewState.isBackgroundTransparent
                == isTransparent
        )
    }

    @Test(
        "shake trigger forwards transparency through its modifier",
        arguments: [false, true]
    )
    func shakeTriggerForwardsTransparency(isTransparent: Bool) {
        let view = Color.clear.logViewer(
            on: .shake,
            isTransparent: isTransparent
        )

        let modifier = findValue(
            of: ShakeLogViewModifier.self,
            in: view
        )

        let logView = modifier?.makeLogView {}

        #expect(modifier?.isTransparent == isTransparent)
        #expect(modifier?.presentation == .overlay)
        #expect(
            logView?.viewState.isBackgroundTransparent
                == isTransparent
        )
    }

    @Test("専用ウインドウ表示方法を各トリガーへ渡す")
    func windowPresentationIsForwardedToEachTrigger() throws {
        let customView = Color.clear.logViewer(
            on: .custom(.constant(false)),
            presentation: .window
        )
        let shakeView = Color.clear.logViewer(
            on: .shake,
            presentation: .window
        )

        let customModifier = try #require(findValue(
            of: CustomLogViewModifier.self,
            in: customView
        ))
        let shakeModifier = try #require(findValue(
            of: ShakeLogViewModifier.self,
            in: shakeView
        ))

        #expect(customModifier.presentation == .window)
        #expect(shakeModifier.presentation == .window)
    }

    @Test(
        "各表示方法が注入された保存機能の後続変更を反映する",
        .timeLimit(.minutes(1))
    )
    func eachViewerUsesItsInjectedStore() async throws {
        let firstStore = InMemoryLogStore()
        let secondStore = InMemoryLogStore()
        firstStore.add(makeEntry(message: "first"))
        secondStore.add(makeEntry(message: "second"))

        let firstView = Color.clear.logViewer(
            on: .custom(.constant(true)),
            store: firstStore
        )
        let secondView = Color.clear.logViewer(
            on: .shake,
            store: secondStore
        )

        let firstModifier = try #require(findValue(
            of: CustomLogViewModifier.self,
            in: firstView
        ))
        let secondModifier = try #require(findValue(
            of: ShakeLogViewModifier.self,
            in: secondView
        ))
        let firstLogView = firstModifier.makeLogView {}
        let secondLogView = secondModifier.makeLogView {}

        #expect(
            firstLogView.viewState.logs.map(\.message)
                == ["first"]
        )
        #expect(
            secondLogView.viewState.logs.map(\.message)
                == ["second"]
        )

        let observationTask = Task {
            await firstLogView.viewState.observeStore()
        }
        defer {
            observationTask.cancel()
        }

        firstStore.add(makeEntry(message: "updated"))
        await waitUntil {
            firstLogView.viewState.logs.map(\.message)
                == ["first", "updated"]
        }
        #expect(
            firstLogView.viewState.logs.map(\.message)
                == ["first", "updated"]
        )

        firstStore.setRecordingEnabled(false)
        await waitUntil {
            !firstLogView.viewState.active
        }
        #expect(!firstLogView.viewState.active)

        firstStore.deleteAll()
        await waitUntil {
            firstLogView.viewState.logs.isEmpty
        }
        #expect(firstLogView.viewState.logs.isEmpty)
    }

    private func makeEntry(message: String) -> LogEntry {
        LogEntry(
            message: message,
            source: SourceLocation(
                fileID: "Test.swift",
                function: "run()",
                line: 1
            )
        )
    }

    private func waitUntil(
        _ condition: () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while !condition(), clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func findValue<Value>(
        of type: Value.Type,
        in root: Any
    ) -> Value? {
        if let value = root as? Value {
            return value
        }

        for child in Mirror(reflecting: root).children {
            if let value = findValue(of: type, in: child.value) {
                return value
            }
        }

        return nil
    }
}
