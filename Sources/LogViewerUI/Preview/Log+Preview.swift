#if DEBUG
import LogViewerCore

extension Log {
    static var apiLog: Log {
        .init(
            message: "APIResponse: abcde",
            tags: ["api"],
            fileID: "APIClient.swift",
            function: "func send(request:)"
        )
    }

    static var apiErrorLog: Log {
        .init(
            message: "APIError: InternalServerError(\"Server Error\")",
            tags: ["error", "api"],
            fileID: "APIClient.swift",
            function: "func send(request:)"
        )
    }

    static var errorLog: Log {
        .init(
            message: "DomainError: Don't find user",
            tags: ["error"],
            fileID: "UserSearch.swift",
            function: "func search(id:)"
        )
    }

    static var infoLog: Log {
        .init(
            message: "User found: John Doe",
            tags: ["info"],
            fileID: "UserSearch.swift",
            function: "func search(id:)"
        )
    }

    static var random: Log {
        switch (0...3).randomElement() {
        case 0: apiLog
        case 1: apiErrorLog
        case 2: errorLog
        default: infoLog
        }
    }
}
#endif
