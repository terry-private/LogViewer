public struct Tag: RawRepresentable, Hashable, Sendable, Equatable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Tag: Comparable {
    public static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Tag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension Tag: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
