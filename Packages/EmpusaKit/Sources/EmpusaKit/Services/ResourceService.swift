import Foundation
import OSLog

public protocol ResourceServiceProtocol {
    func fetchResources(for volume: ExternalVolume) async -> [DisplayingSwitchResource]
}

public final class ResourceService: ResourceServiceProtocol {
    // MARK: - Dependencies
    private let assetService: AssetServiceProtocol = AssetService()
    private let storageService: StorageServiceProtocol = StorageService()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "ResourceService")

    // MARK: - Public functions
    public init() {}

    public func fetchResources(
        for volume: ExternalVolume
    ) async -> [DisplayingSwitchResource] {
        var displayingResources = [DisplayingSwitchResource]()
        let log = storageService.getLog(at: volume)

        for resource in SwitchResource.allCases {
            let isInstalled = log?.isResourceInstalled(resource) ?? false

            switch resource.source {
            case .github(let url, _), .forgejo(let url, _):
                displayingResources.append(
                    .init(
                        resource: resource,
                        version: try? await assetService.fetchRepositoryRelease(for: url).tagName,
                        preChecked: !(resource.uncheckedIfInstalled && isInstalled)
                    )
                )

            case .link(_, let version):
                displayingResources.append(
                    .init(
                        resource: resource,
                        version: version,
                        preChecked: !(resource.uncheckedIfInstalled && isInstalled)
                    )
                )
            }
        }

        return displayingResources
    }
}
