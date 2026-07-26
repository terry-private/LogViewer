import SwiftUI
import Testing
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
        #expect(
            logView?.viewState.isBackgroundTransparent
                == isTransparent
        )
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
