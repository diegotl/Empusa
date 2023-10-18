import Foundation
import OSLog

public protocol ResourceServiceProtocol {
    func fetchResources() async -> [DisplayingSwitchResource]
}

public final class ResourceService: ResourceServiceProtocol {
    // MARK: - Dependencies
    private let assetService: AssetServiceProtocol = AssetService()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.Services", category: "ResourceService")

    // MARK: - Public functions
    public init() {}

    public func fetchResources() async -> [DisplayingSwitchResource] {
        var displayingResources = [DisplayingSwitchResource]()

        for resource in SwitchResource.allCases {
            switch resource.source {
            case .github(let url, _), .forgejo(let url, _):
                displayingResources.append(
                    .init(
                        resource: resource,
                        version: try? await assetService.fetchRepositoryRelease(for: url).tagName
                    )
                )

            case .link(_, let version):
                displayingResources.append(
                    .init(
                        resource: resource,
                        version: version
                    )
                )
            }
        }

        return displayingResources
    }
}
