import Foundation
import OSLog
import EmpusaMacros

public protocol ResourceServiceProtocol {
    func fetchResources() async throws -> [CategoryData]
}

public final class ResourceService: ResourceServiceProtocol {
    // MARK: - Dependencies
    private let client: ClientProtocol = Client()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "ResourceService")

    // MARK: - Public functions
    public init() {}

    public func fetchResources() async throws -> [CategoryData] {
        try await client.request(
            url: #URL("https://empusa.pacotevicio.app/resources/list")
        )
    }
}
