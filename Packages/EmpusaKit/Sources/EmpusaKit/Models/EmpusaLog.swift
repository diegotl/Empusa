import Foundation

public struct InstalledResource: Codable {
    let name: String
    let version: String?
    var updatedAt: Date = Date()
}

public final class EmpusaLog: Codable {
    var resources: [InstalledResource] = []

    func add(
        resource: ResourceData,
        version: String?
    ) {
        resources.removeAll(where: { $0.name == resource.name })
        resources.append(.init(
            name: resource.name,
            version: version
        ))
    }

    public func installedVersion(_ resource: ResourceData) -> String? {
        resources.first(where: { $0.name == resource.name })?.version
    }
}
