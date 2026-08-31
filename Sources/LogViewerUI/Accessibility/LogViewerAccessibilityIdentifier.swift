enum LogViewerAccessibilityIdentifier {
    static let close = "logviewer.close"
    static let search = "logviewer.search"
    static let clearSearch = "logviewer.search.clear"
    static let actions = "logviewer.actions"
    static let pause = "logviewer.actions.pause"
    static let resume = "logviewer.actions.resume"
    static let copy = "logviewer.actions.copy"
    static let shareText = "logviewer.actions.share-text"
    static let shareJSON = "logviewer.actions.share-json"
    static let delete = "logviewer.actions.delete"
    static let confirmDelete = "logviewer.delete.confirm"
    static let cancelDelete = "logviewer.delete.cancel"
    static let paused = "logviewer.state.paused"
    static let empty = "logviewer.state.empty"
    static let resultCount = "logviewer.filter.result-count"
    static let clearFilter = "logviewer.filter.clear"
    static let scrollToBottom = "logviewer.scroll-to-bottom"

    static func level(_ level: String) -> String {
        "logviewer.filter.level.\(level)"
    }

    static func tag(_ tag: String) -> String {
        "logviewer.filter.tag.\(tag)"
    }
}
