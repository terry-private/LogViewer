enum LogFilter: Hashable, Equatable, Sendable {
    case all
    case search(String)
    case tag(Set<Tag>)
}
