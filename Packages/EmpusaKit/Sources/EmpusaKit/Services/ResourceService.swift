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
            let isInstalled = log?.isInstalled(resource) ?? false
            let installedVersion = log?.installedVersion(resource)

            switch resource.source {
            case .github, .forgejo:
                let availableVersion = try? await assetService.fetchRepositoryRelease(for: resource).tagName
                let updateAvailable: Bool = {
                    if let installedVersion, let availableVersion, availableVersion.isHigherThan(installedVersion) {
                        return true
                    }

                    return false
                }()

                displayingResources.append(
                    .init(
                        resource: resource,
                        version: availableVersion,
                        preChecked: !isInstalled || (updateAvailable && !resource.uncheckedIfInstalled)
                    )
                )

            case .link(_, let version):
                let updateAvailable: Bool = {
                    if let installedVersion, let version, installedVersion != version {
                        return true
                    }

                    return false
                }()

                displayingResources.append(
                    .init(
                        resource: resource,
                        version: version,
                        preChecked: !isInstalled || (updateAvailable && !resource.uncheckedIfInstalled)
                    )
                )
            }
        }

        return displayingResources
    }
}
