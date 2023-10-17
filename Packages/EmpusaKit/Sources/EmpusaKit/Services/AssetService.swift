import Foundation
import Combine
import OSLog

enum AssetServiceError: Error {
    case assetNotFound
}

public protocol AssetServiceProtocol {
    func fetchGitHubRelease(for resourceUrl: URL) async throws -> GitHubRelease
    func downloadAsset(for resource: SwitchResource, progressSubject: CurrentValueSubject<Double, Never>) async throws -> Data
}

public final class AssetService: AssetServiceProtocol {
    private let client: ClientProtocol = Client()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.Services", category: "AssetService")

    public init() {}

    // MARK: - Public functions

    public func fetchGitHubRelease(
        for resourceUrl: URL
    ) async throws -> GitHubRelease {
        return try await client.request(url: resourceUrl)
    }

    public func downloadAsset(
        for resource: SwitchResource,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> Data {
        switch resource.source {
        case .github(let url, let assetPrefix):
            let release = try await fetchGitHubRelease(for: url)
            guard let asset = release
                .assets
                .first(where: { $0.name.hasPrefix(assetPrefix) })
            else {
                throw AssetServiceError.assetNotFound
            }

            logger.info("Will download asset \(asset.name) for \(release.name) (\(release.tagName))")

            return try await client.downloadFile(
                url: asset.browserDownloadUrl,
                progressSubject: progressSubject
            )

        case .link(let url, _):
            return try await client.downloadFile(
                url: url,
                progressSubject: progressSubject
            )
        }
    }
}
