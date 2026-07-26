import Foundation
import OrderedCollections

package struct Log: Sendable, Hashable, Identifiable {
    package let id: String
    package let tags: OrderedSet<Tag>
    package let fileID: String
    package let function: String
    package let message: String
    package let time: Date
    package init(id: String = UUID().uuidString, message: String, tags: OrderedSet<Tag>, fileID: String, function: String, time: Date = Date()) {
        self.id = id
        self.message = message
        self.tags = tags
        self.fileID = fileID
        self.function = function
        self.time = time
    }
}

// MARK: filters
package extension [Log] {
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
