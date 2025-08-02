internal enum Period: String, CaseIterable, Identifiable {
    case all
    case file
    case function
    var id: String { rawValue }
}
