import Foundation
import LogViewer
import Observation
import UIKit

@MainActor
@Observable
final class SampleSceneModel {
    let sceneName: String
    let store: InMemoryLogStore
    let logger: Logger

    var showLogs = false
    var showSheet = false
    var showFullScreen = false
    var showAlert = false
    var hostInput = ""
    var clipboardPreview = ""
    var sceneShakeCount = 0

    init(sceneName: String) {
        self.sceneName = sceneName
        let store = InMemoryLogStore(privacyPolicy: .standard)
        self.store = store
        self.logger = Logger(store: store)
        seedLogs()
    }

    func seedLogs() {
        logger.add(LogEntry(
            level: .info,
            message: "network included \(sceneName) owner@example.com",
            source: SourceLocation(
                fileID: "Sample/NetworkClient.swift",
                function: "fetch()",
                line: 42
            ),
            category: "sample",
            tags: ["network", Tag(rawValue: sceneName)],
            metadata: ["authorization": "Bearer secret-token"]
        ))
        logger.add(LogEntry(
            level: .warning,
            message: "database excluded \(sceneName)",
            source: SourceLocation(
                fileID: "Sample/Database.swift",
                function: "save()",
                line: 24
            ),
            category: "sample",
            tags: ["database", Tag(rawValue: sceneName)]
        ))
    }

    func inspectClipboard() {
        clipboardPreview = UIPasteboard.general.string ?? ""
    }
}
