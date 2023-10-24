import Foundation

public struct InstalledResource: Codable {
    let name: SwitchResource
    let version: String?
    var updatedAt: Date = Date()
}

public final class EmpusaLog: Codable {
    var resources: [InstalledResource] = []

    func add(
        resource: SwitchResource,
        version: String?
    ) {
        resources.removeAll(where: { $0.name == resource })
        resources.append(.init(
            name: resource,
            version: version
        ))
    }

    func isInstalled(_ resource: SwitchResource) -> Bool {
        resources.contains(where: {$0.name == resource })
    }

    func installedVersion(_ resource: SwitchResource) -> String? {
        resources.first(where: { $0.name == resource })?.version
    }
}
