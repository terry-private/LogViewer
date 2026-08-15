internal enum Period: CaseIterable, Identifiable {
    case all
    case file
    case function
    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            LogViewerLocalization.string(.groupingAll)
        case .file:
            LogViewerLocalization.string(.groupingFile)
        case .function:
            LogViewerLocalization.string(.groupingFunction)
        }
    }
}
