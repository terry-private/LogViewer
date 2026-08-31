/// ログの分類と絞り込みに使う文字列タグ。
public struct Tag: RawRepresentable, Codable, Hashable, Sendable, Equatable {
    /// タグの文字列表現。
    public var rawValue: String
    /// 文字列からタグを作成する。
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Tag: Comparable {
    /// 文字列表現の昇順で比較する。
    public static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Tag: ExpressibleByStringLiteral {
    /// 文字列リテラルからタグを作成する。
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension Tag: CustomStringConvertible {
    /// タグの文字列表現。
    public var description: String {
        rawValue
    }
}
