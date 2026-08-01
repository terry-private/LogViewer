import LogViewerCore
import Observation

@MainActor
@Observable
internal final class LogViewState {
    private let store: any LogStore
    private var snapshot: LogStoreSnapshot
    private var cachedTags: [Tag] = []
    private var cachedLogs: [LogEntry] = []
    private var cachedFileTags: [String] = []
    private var cachedFunctionTags: [String] = []
    private var cachedFileLogIndices: [String: [Int]] = [:]
    private var cachedFunctionLogIndices: [String: [Int]] = [:]
    var selectedPeriod = Period.all
    var filter: LogFilter = .all {
        didSet {
            rebuildFilteredCaches()
        }
    }
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
        rebuildSnapshotCaches()
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
        cachedTags
    }
    internal var active: Bool { snapshot.isRecordingEnabled }
    internal var logs: [LogEntry] {
        cachedLogs
    }
    internal var fileTags: [String] {
        cachedFileTags
    }
    internal var functionTags: [String] {
        cachedFunctionTags
    }
    internal func fileLogs(for name: String) -> [LogEntry] {
        logs(at: cachedFileLogIndices[name] ?? [])
    }
    internal func functionLogs(for functionTag: String) -> [LogEntry] {
        logs(at: cachedFunctionLogIndices[functionTag] ?? [])
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
            rebuildSnapshotCaches()
        }
    }

    private func rebuildSnapshotCaches() {
        var seenTags: Set<Tag> = []
        var seenFiles: Set<String> = []
        var seenFunctions: Set<String> = []
        var tags: [Tag] = []
        var files: [String] = []
        var functions: [String] = []

        for entry in snapshot.entries {
            for tag in entry.tags where seenTags.insert(tag).inserted {
                tags.append(tag)
            }
            if seenFiles.insert(entry.source.fileID).inserted {
                files.append(entry.source.fileID)
            }
            let functionKey = functionKey(for: entry)
            if seenFunctions.insert(functionKey).inserted {
                functions.append(functionKey)
            }
        }

        cachedTags = tags
        cachedFileTags = files
        cachedFunctionTags = functions
        rebuildFilteredCaches()
    }

    private func rebuildFilteredCaches() {
        let logs = snapshot.entries.filter(by: filter)
        var fileLogIndices: [String: [Int]] = [:]
        var functionLogIndices: [String: [Int]] = [:]

        for (index, entry) in logs.enumerated() {
            fileLogIndices[entry.source.fileID, default: []].append(index)
            functionLogIndices[functionKey(for: entry), default: []]
                .append(index)
        }

        cachedLogs = logs
        cachedFileLogIndices = fileLogIndices
        cachedFunctionLogIndices = functionLogIndices
    }

    private func functionKey(for entry: LogEntry) -> String {
        entry.source.fileID + "\n> " + entry.source.function
    }

    private func logs(at indices: [Int]) -> [LogEntry] {
        indices.map { cachedLogs[$0] }
    }
}
