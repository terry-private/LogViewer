import Foundation

package enum TagMatchMode: Hashable, Sendable {
    case any
    case all
}

package enum LogFilterPeriod: Hashable, Sendable, CaseIterable {
    case all
    case lastFiveMinutes
    case lastHour
    case lastDay

    package var duration: TimeInterval? {
        switch self {
        case .all: nil
        case .lastFiveMinutes: 5 * 60
        case .lastHour: 60 * 60
        case .lastDay: 24 * 60 * 60
        }
    }

    package var refreshGranularity: TimeInterval? {
        switch self {
        case .all: nil
        case .lastFiveMinutes: 1
        case .lastHour: 10
        case .lastDay: 60
        }
    }

    package func transitionDate(
        for timestamp: Date,
        now: Date
    ) -> Date? {
        guard
            let duration,
            let refreshGranularity
        else {
            return nil
        }

        let transition: Date
        if timestamp > now {
            transition = timestamp
        } else {
            transition = timestamp.addingTimeInterval(duration)
            guard transition >= now else { return nil }
        }

        let bucket = ceil(
            transition.timeIntervalSince1970 / refreshGranularity
        ) * refreshGranularity
        return Date(timeIntervalSince1970: bucket)
    }
}

package struct LogFilter: Hashable, Sendable {
    package var searchText: String
    package var levels: Set<LogLevel>
    package var tags: Set<Tag>
    package var tagMatchMode: TagMatchMode
    package var period: LogFilterPeriod

    package init(
        searchText: String = "",
        levels: Set<LogLevel> = [],
        tags: Set<Tag> = [],
        tagMatchMode: TagMatchMode = .any,
        period: LogFilterPeriod = .all
    ) {
        self.searchText = searchText
        self.levels = levels
        self.tags = tags
        self.tagMatchMode = tagMatchMode
        self.period = period
    }

    package static let all = LogFilter()

    package static func search(_ text: String) -> LogFilter {
        LogFilter(searchText: text)
    }

    package static func tag(_ tags: Set<Tag>) -> LogFilter {
        LogFilter(tags: tags)
    }

    package var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !levels.isEmpty
            || !tags.isEmpty
            || period != .all
    }
}
