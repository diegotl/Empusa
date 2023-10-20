import Foundation
import Combine
import OSLog

enum AssetServiceError: Error {
    case assetNotFound
}

public protocol AssetServiceProtocol {
    func fetchRepositoryRelease(for resourceUrl: URL) async throws -> RepositoryRelease
    func downloadAsset(for resource: SwitchResource, progressSubject: CurrentValueSubject<Double, Never>) async throws -> DownloadedAsset
}

public final class AssetService: AssetServiceProtocol {
    private let client: ClientProtocol = Client()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "AssetService")

    public init() {}

    // MARK: - Public functions

    public func fetchRepositoryRelease(
        for resourceUrl: URL
    ) async throws -> RepositoryRelease {
        return try await client.request(url: resourceUrl)
    }

    public func downloadAsset(
        for resource: SwitchResource,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> DownloadedAsset {
        switch resource.source {
        case .github(let url, let assetPrefix), .forgejo(let url, let assetPrefix):
            let release = try await fetchRepositoryRelease(for: url)
            guard let asset = release
                .assets
                .first(where: { $0.name.hasPrefix(assetPrefix) })
            else {
                throw AssetServiceError.assetNotFound
            }

            logger.info("Will download asset \(asset.name) for \(release.name) (\(release.tagName))")

            let assetUrl = try await client.downloadFile(
                url: asset.browserDownloadUrl,
                progressSubject: progressSubject
            )

            return .init(
                version: release.tagName,
                url: assetUrl
            )

        case .link(let url, let version):
            let assetUrl =  try await client.downloadFile(
                url: url,
                progressSubject: progressSubject
            )

            return .init(
                version: version,
                url: assetUrl
            )
        }
    }
}
