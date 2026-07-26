import SwiftUI
import Testing
import LogViewer

@Suite("Public API")
@MainActor
struct PublicAPITests {
    @Test("documented logger calls compile")
    func documentedLoggerCallsCompile() {
        let logger = LogViewer.Logger.shared

        logger.add("User logged in")
        logger.add("Request completed", tags: "api", "network")
        logger.add("Profile updated", tags: ["user", "success"])
    }

    @Test("documented view modifiers compile")
    func documentedViewModifiersCompile() {
        _ = CustomTriggerConsumerView()
        _ = ShakeTriggerConsumerView()
    }
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
