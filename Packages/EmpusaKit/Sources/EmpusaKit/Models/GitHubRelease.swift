import Foundation

public struct GitHubReleaseAsset: Identifiable, Decodable {
    public let id: Int
    let name: String
    let browserDownloadUrl: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

public struct GitHubRelease: Identifiable, Decodable {
    public let id: Int
    let name: String
    public let tagName: String
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tagName = "tag_name"
        case assets
    }
}
