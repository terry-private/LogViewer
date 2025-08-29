import Observation

@MainActor
@Observable
internal final class LogViewState {
    private var store: Logger = .shared
    var selectedPeriod = Period.all
    var filter: LogFilter = .all
    internal var searchKey: String = ""
    let selectedTag: Set<Tag> = []
    var fileExpands: String?
    var functionExpands: String?
    var isBackgroundTransparent: Bool {
        get { store.isBackgroundTransparent }
        set { store.isBackgroundTransparent = newValue }
    }
    var displayLogs: [Log] {
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
        Array(store.tags)
    }
    internal var active: Bool { store.active }
    internal var logs: [Log] { store.logs.filter(by: filter) }
    internal var fileTags: [String] { Array(store.fileTagToLogs.keys) }
    internal var functionTags: [String] { Array(store.functionTagToLogs.keys) }
    internal func fileLogs(for name: String) -> [Log] {
        store.fileTagToLogs[name]?.filter(by: filter) ?? []
    }
    internal func functionLogs(for functionTag: String) -> [Log] {
        store.functionTagToLogs[functionTag]?.filter(by: filter) ?? []
    }
    internal func toggleActive() {
        store.active.toggle()
    }
    internal func deleteLogs() {
        store.deleteAll()
    }
}
