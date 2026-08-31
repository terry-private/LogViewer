import LogViewer
import SwiftUI

@main
struct LogViewerSampleApp: App {
    var body: some Scene {
        WindowGroup {
            SampleSceneView(sceneName: "main")
        }

        WindowGroup(SampleText.secondaryWindow, id: "secondary") {
            SampleSceneView(sceneName: "secondary")
        }
    }
}
