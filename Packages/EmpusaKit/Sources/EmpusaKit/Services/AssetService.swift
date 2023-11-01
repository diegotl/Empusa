import Foundation
import Combine
import OSLog

public protocol AssetServiceProtocol {
    func downloadAsset(for release: ReleaseData, progressSubject: CurrentValueSubject<Double, Never>) async throws -> DownloadedAsset
}

public final class AssetService: AssetServiceProtocol {
    // MARK: - Dependencies
    private let client: ClientProtocol = Client()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "AssetService")
    
    // MARK: - Init
    public init() {}

    // MARK: - Public functions
    public func downloadAsset(
        for release: ReleaseData,
        progressSubject: CurrentValueSubject<Double, Never>
    ) async throws -> DownloadedAsset {
        logger.info("Will download asset \(release.assetFileName) (\(release.version ?? ""))")

        let assetUrl = try await client.downloadFile(
            url: release.assetUrl,
            progressSubject: progressSubject
        )

        return .init(
            version: release.version,
            url: assetUrl
        )
    }
}
