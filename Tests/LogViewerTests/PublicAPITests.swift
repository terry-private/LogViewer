import SwiftUI
import Testing
import LogViewer

@Suite("Public API")
@MainActor
struct PublicAPITests {
    @Test("documented logger calls compile")
    func documentedLoggerCallsCompile() {
        let documentedCalls: @MainActor () -> Void = {
            let logger = LogViewer.Logger.shared

            logger.add("User logged in")
            logger.add("Request completed", tags: "api", "network")
            logger.add("Profile updated", tags: ["user", "success"])
        }

        _ = documentedCalls
    }

    @Test("documented view modifiers compile")
    func documentedViewModifiersCompile() {
        _ = CustomTriggerConsumerView()
        _ = ShakeTriggerConsumerView()
    }
}

@MainActor
private func documentedContextCall(id: String) {
    LogViewer.Logger.shared.add(
        "Fetching user: \(id)",
        tags: "api", "user"
    )
}

private struct CustomTriggerConsumerView: View {
    @State private var isPresented = false

    var body: some View {
        Color.clear
            .logViewer(
                on: .custom($isPresented),
                isTransparent: true
            )
    }
}

private struct ShakeTriggerConsumerView: View {
    var body: some View {
        Color.clear
            .logViewer(on: .shake)
    }
}
