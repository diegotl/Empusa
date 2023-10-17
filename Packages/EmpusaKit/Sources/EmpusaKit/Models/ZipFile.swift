import UniformTypeIdentifiers
import SwiftUI

public struct ZipFile: FileDocument {
    public static var readableContentTypes = [UTType.zip]

    public let url: URL

    public init(url: URL) {
        self.url = url
    }
    
    public init(configuration: ReadConfiguration) throws {
        fatalError("Needs to be implemented")
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try .init(url: url)
    }
}
