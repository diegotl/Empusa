import Foundation

public final class ExternalVolume: Identifiable, Hashable {
    public static let none = ExternalVolume(id: "", name: "None", icon: nil, path: "", capacity: 0)

    public let id: String
    public let name: String
    public let icon: Data?
    public let path: String
    public let capacity: Int64

    public var url: URL {
        URL(fileURLWithPath: path)
    }

    public var formattedCapacity: String {
        ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
    }

    public init(id: String, name: String, icon: Data?, path: String, capacity: Int64) {
        self.id = id
        self.name = name
        self.icon = icon
        self.path = path
        self.capacity = capacity
    }

    public static func == (lhs: ExternalVolume, rhs: ExternalVolume) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(path)
    }
}
