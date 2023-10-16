import Foundation

public struct ExternalStorage: Identifiable, Hashable {
    public static let none = ExternalStorage(id: "", name: "None", path: "", capacity: 0)

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
