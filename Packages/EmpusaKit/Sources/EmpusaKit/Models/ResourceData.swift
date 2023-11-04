import Foundation

public struct InstallStep: Decodable, Equatable, Hashable {
    public enum Operation: String, Decodable {
        case mergeAll
        case mergeDir
        case moveFile
    }

    public let operation: Operation
    public let origin: String?
    public let destination: String?
}

public struct ReleaseData: Decodable, Equatable, Hashable {
    public let version: String?
    public let assetUrl: URL
    public let assetFileName: String
    public let installSteps: [InstallStep]

    enum CodingKeys: String, CodingKey {
        case version
        case assetUrl = "asset_url"
        case assetFileName = "asset_filename"
        case installSteps = "install_steps"
    }

    var fileType: String {
        assetFileName
            .components(separatedBy: ".")
            .last!
    }
}


public struct ResourceData: Decodable, Equatable, Hashable {
    public let name: String
    public let displayName: String
    public let additionalDescription: String?
    public let stableRelease: ReleaseData
    public let preRelease: ReleaseData?

    public var formattedName: String {
        [displayName, additionalDescription]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case additionalDescription = "additional_description"
        case stableRelease = "stable_release"
        case preRelease = "pre_release"
    }
}

public struct CategoryData: Decodable, Hashable {
    public let name: String
    public let resources: [ResourceData]
}
