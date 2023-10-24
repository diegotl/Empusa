import Foundation
import Combine
import OSLog

enum AssetServiceError: Error {
    case assetNotFound
}

public protocol AssetServiceProtocol {
    func fetchRepositoryReleases(for resource: SwitchResource) async throws -> [RepositoryRelease]
    func fetchRepositoryRelease(for resource: SwitchResource) async throws -> RepositoryRelease
    func downloadAsset(for resource: SwitchResource, progressSubject: CurrentValueSubject<Double, Never>) async throws -> DownloadedAsset
}

public final class AssetService: AssetServiceProtocol {
    // MARK: - Dependencies
    private let userDefaultsService: UserDefaultsServiceProtocol = UserDefaultsService()
    private let client: ClientProtocol = Client()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "AssetService")
    
    // MARK: - Init
    public init() {}

    // MARK: - Public functions
    public func fetchRepositoryReleases(
        for resource: SwitchResource
    ) async throws -> [RepositoryRelease] {
        try await client.request(url: resource.source.releasesUrl)
    }

    public func fetchRepositoryRelease(
        for resource: SwitchResource
    ) async throws -> RepositoryRelease {
        let preferPreReleaseVersions = userDefaultsService.boolForKey(.preferPreReleaseVersions)
        if preferPreReleaseVersions {
            let allReleases = try await fetchRepositoryReleases(for: resource)
            if let latestRelease = allReleases.first, latestRelease.prerelease {
                return latestRelease
            }
        }

        return try await client.request(url: resource.source.latestReleaseUrl)
    }

    public func downloadAsset(
        for resource: SwitchResource,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> DownloadedAsset {
        switch resource.source {
        case .github(_, _, let assetPrefix), .forgejo(_, _, let assetPrefix):
            let release = try await fetchRepositoryRelease(for: resource)

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
