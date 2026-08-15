import Foundation
import LogViewerCore
import Observation

@MainActor
@Observable
internal final class LogViewState {
    private let store: any LogStore
    private let privacyPolicy: LogPrivacyPolicy
    private var snapshot: LogStoreSnapshot
    private var protectedEntries: [LogEntry] = []
    private var cachedTags: [Tag] = []
    private var cachedLogs: [LogEntry] = []
    private var cachedFileTags: [String] = []
    private var cachedFunctionTags: [String] = []
    private var cachedFileLogIndices: [String: [Int]] = [:]
    private var cachedFunctionLogIndices: [String: [Int]] = [:]
    private var cachedRelativePeriodTransitionDate: Date?
    private(set) var periodScheduleRevision: UInt = 0
    var selectedPeriod = Period.all
    var filter: LogFilter = .all {
        didSet {
            rebuildFilteredCaches()
            periodScheduleRevision &+= 1
        }
    }
    var fileExpands: String?
    var functionExpands: String?
    var isBackgroundTransparent: Bool

    init(
        store: any LogStore = Logger.shared.store,
        privacyPolicy: LogPrivacyPolicy = .none,
        isBackgroundTransparent: Bool = false
    ) {
        self.store = store
        self.privacyPolicy = privacyPolicy
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
    internal var resultCount: Int {
        cachedLogs.count
    }
    internal var totalCount: Int {
        snapshot.entries.count
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

    internal func exportData(format: LogExportFormat) throws -> Data {
        try LogExporter().data(from: cachedLogs, format: format)
    }

    internal func exportString(format: LogExportFormat) throws -> String {
        try LogExporter().string(from: cachedLogs, format: format)
    }

    internal func observeStore() async {
        for await snapshot in store.updates() {
            guard !Task.isCancelled else { return }
            self.snapshot = snapshot
            rebuildSnapshotCaches()
            periodScheduleRevision &+= 1
        }
    }

    internal func refreshRelativePeriod(at now: Date = .now) {
        guard filter.period != .all else { return }
        rebuildFilteredCaches(now: now)
        periodScheduleRevision &+= 1
    }

    internal func waitForNextRelativePeriodTransition() async {
        guard let transitionDate = cachedRelativePeriodTransitionDate else {
            return
        }
        let delay = max(
            transitionDate.timeIntervalSinceNow + 0.001,
            0.001
        )
        do {
            try await Task.sleep(for: .seconds(delay))
        } catch {
            return
        }
        refreshRelativePeriod()
    }

    internal func nextRelativePeriodTransitionDate(
        at now: Date = .now
    ) -> Date? {
        protectedEntries.filterResult(by: filter, now: now)
            .nextTransitionDate
    }

    private func rebuildSnapshotCaches() {
        var seenTags: Set<Tag> = []
        var tags: [Tag] = []

        protectedEntries = privacyPolicy.redacting(snapshot.entries)

        for entry in protectedEntries {
            for tag in entry.tags where seenTags.insert(tag).inserted {
                tags.append(tag)
            }
        }

        cachedTags = tags
        rebuildFilteredCaches()
    }

    private func rebuildFilteredCaches(now: Date = .now) {
        let result = protectedEntries.filterResult(by: filter, now: now)
        let logs = result.entries
        var files: [String] = []
        var functions: [String] = []
        var seenFiles: Set<String> = []
        var seenFunctions: Set<String> = []
        var fileLogIndices: [String: [Int]] = [:]
        var functionLogIndices: [String: [Int]] = [:]

        for (index, entry) in logs.enumerated() {
            if seenFiles.insert(entry.source.fileID).inserted {
                files.append(entry.source.fileID)
            }
            let functionKey = functionKey(for: entry)
            if seenFunctions.insert(functionKey).inserted {
                functions.append(functionKey)
            }
            fileLogIndices[entry.source.fileID, default: []].append(index)
            functionLogIndices[functionKey, default: []]
                .append(index)
        }

        cachedLogs = logs
        cachedRelativePeriodTransitionDate = result.nextTransitionDate
        cachedFileTags = files
        cachedFunctionTags = functions
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
