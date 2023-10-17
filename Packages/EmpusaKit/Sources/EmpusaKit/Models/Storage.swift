import Foundation

public struct ExternalVolume: Identifiable, Hashable {
    public static let none = ExternalVolume(id: "", name: "None", path: "", capacity: 0)

    public let id: String
    public let name: String
    public let path: String
    public let capacity: Int64

    public var url: URL {
        URL(fileURLWithPath: path)
    }

    public var formattedCapacity: String {
        ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
    }
}
