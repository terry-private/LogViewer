#if DEBUG
import LogViewerCore

extension LogEntry {
    static var apiLog: LogEntry {
        .init(
            message: "APIResponse: abcde",
            source: .init(
                fileID: "APIClient.swift",
                function: "func send(request:)"
            ),
            tags: ["api"]
        )
    }

    static var apiErrorLog: LogEntry {
        .init(
            message: "APIError: InternalServerError(\"Server Error\")",
            source: .init(
                fileID: "APIClient.swift",
                function: "func send(request:)"
            ),
            tags: ["error", "api"]
        )
    }

    static var errorLog: LogEntry {
        .init(
            message: "DomainError: Don't find user",
            source: .init(
                fileID: "UserSearch.swift",
                function: "func search(id:)"
            ),
            tags: ["error"]
        )
    }

    static var infoLog: LogEntry {
        .init(
            message: "User found: John Doe",
            source: .init(
                fileID: "UserSearch.swift",
                function: "func search(id:)"
            ),
            tags: ["info"]
        )
    }

    static var random: LogEntry {
        switch (0...3).randomElement() {
        case 0: apiLog
        case 1: apiErrorLog
        case 2: errorLog
        default: infoLog
        }
    }
}
#endif
