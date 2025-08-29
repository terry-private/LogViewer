import Foundation
import OrderedCollections

internal struct Log: Sendable, Hashable, Identifiable {
    let id: String
    let tags: OrderedSet<Tag>
    let fileID: String
    let function: String
    let message: String
    let time: Date
    init (id: String = UUID().uuidString, message: String, tags: OrderedSet<Tag>, fileID: String, function: String, time: Date = Date()) {
        self.id = id
        self.message = message
        self.tags = tags
        self.fileID = fileID
        self.function = function
        self.time = time
    }
}

// MARK: filters
internal extension [Log] {
    func filter(by tags: Set<Tag>) -> [Log] {
        if tags.isEmpty {
            lazy.filter { log in
                log.tags.isEmpty
            }
        } else {
            lazy.filter { log in
                !tags.isDisjoint(with: log.tags)
            }
        }
    }

    func filter(by logFilter: LogFilter) -> [Log] {
        switch logFilter {
        case .all:
            self
        case .search(let key):
            lazy.filter { log in
                key.isEmpty ||
                log.message.contains(key) ||
                log.fileID.contains(key) ||
                log.function.contains(key)
            }
        case .tag(let tags):
            filter(by: tags)
        }
    }
}

// MARK: dummys
internal extension Log {
    static var apiLog: Log {
        .init(message: "APIResponse: abcde", tags: ["api"], fileID: "APIClient.swift", function: "func send(request:)")
    }
    static var apiErrorLog: Log {
        .init(message: "APIError: InternalServerError(\"Server Error\", httpStatusCode: 400, underlyingError: nil, request: exampleRequest(), token: abcdefghijklmnopqrstuvwxyz0123456789)", tags: ["error", "api"], fileID: "APIClient.swift", function: "func send(request:)")
    }
    static var errorLog: Log {
        .init(message: "DomainError: Don't find user", tags: ["error"], fileID: "UserSearch.swift", function: "func search(id:)")
    }
    static var infoLog: Log {
        .init(message: "User found: John Doe\n id: 12345 \n email: john@example.com \n age: 30 \n location: New York City \n joined: 2020-01-01T00:00:00Z \n lastLogin: 2020-01-02T00:00:00Z \n avatar: https://example.com/avatar.png \n bio: nil \n website: nil \n stars: 0 \n followers: 0 \n following: 0", tags: ["info"], fileID: "UserSearch.swift", function: "func search(id:)")
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
