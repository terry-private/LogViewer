import LogViewerCore
import Observation

@MainActor
@Observable
internal final class LogViewState {
    private let store: any LogStore
    private var snapshot: LogStoreSnapshot
    var selectedPeriod = Period.all
    var filter: LogFilter = .all
    internal var searchKey: String = ""
    let selectedTag: Set<Tag> = []
    var fileExpands: String?
    var functionExpands: String?
    var isBackgroundTransparent: Bool

    init(
        store: any LogStore = Logger.shared.store,
        isBackgroundTransparent: Bool = false
    ) {
        self.store = store
        snapshot = store.snapshot()
        self.isBackgroundTransparent = isBackgroundTransparent
    }

    var displayLogs: [LogEntry] {
        switch selectedPeriod {
        case .all: logs
        case .file:
            fileTags.last {
                fileExpands == $0
            }
            .map {
                fileLogs(for: $0)
            } ?? []
        case .function:
            functionTags.last {
                functionExpands == $0
            }
            .map {
                functionLogs(for: $0)
            } ?? []
        }
    }
    internal var tags: [Tag] {
        var seen: Set<Tag> = []
        return snapshot.entries
            .flatMap(\.tags)
            .filter { seen.insert($0).inserted }
    }
    internal var active: Bool { snapshot.isRecordingEnabled }
    internal var logs: [LogEntry] {
        snapshot.entries.filter(by: filter)
    }
    internal var fileTags: [String] {
        orderedUnique(
            snapshot.entries.map(\.source.fileID)
        )
    }
    internal var functionTags: [String] {
        orderedUnique(
            snapshot.entries.map {
                $0.source.fileID + "\n> " + $0.source.function
            }
        )
    }
    internal func fileLogs(for name: String) -> [LogEntry] {
        snapshot.entries
            .filter { $0.source.fileID == name }
            .filter(by: filter)
    }
    internal func functionLogs(for functionTag: String) -> [LogEntry] {
        snapshot.entries
            .filter {
                $0.source.fileID + "\n> " + $0.source.function
                    == functionTag
            }
            .filter(by: filter)
    }
    internal func toggleActive() {
        store.setRecordingEnabled(!snapshot.isRecordingEnabled)
    }
    internal func deleteLogs() {
        store.deleteAll()
    }

    internal func observeStore() async {
        for await snapshot in store.updates() {
            guard !Task.isCancelled else { return }
            self.snapshot = snapshot
        }
    }

    private func orderedUnique<Value: Hashable>(
        _ values: [Value]
    ) -> [Value] {
        var seen: Set<Value> = []
        return values.filter { seen.insert($0).inserted }
    }
}
