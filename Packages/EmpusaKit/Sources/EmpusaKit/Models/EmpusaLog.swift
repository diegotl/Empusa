import Foundation

public struct InstalledResource: Codable {
    let resource: SwitchResource
    let version: String?
    var updatedAt: Date = Date()
}

public final class EmpusaLog: Codable {
    var resources: [InstalledResource] = []

    func add(
        resource: SwitchResource,
        version: String?
    ) {
        resources.removeAll(where: { $0.resource == resource })
        resources.append(.init(
            resource: resource,
            version: version
        ))
    }
}
