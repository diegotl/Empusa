import Foundation
import Combine

// MARK: - DisplayingSwitchResource

public struct DisplayingSwitchResource: Hashable {
    public let resource: SwitchResource
    public let version: String?

    public var formattedName: String {
        if let version {
            return "\(resource.rawValue.capitalized) \(version)"
        }

        return resource.rawValue.capitalized
    }

    public init(resource: SwitchResource, version: String? = nil) {
        self.resource = resource
        self.version = version
    }
}

// MARK: - SwitchResource

public enum SwitchResouceSource {
    case github(URL, assetPrefix: String)
    case link(URL, version: String)
}

public enum SwitchResource: String, CaseIterable {
    case hekate
    case atmosphere
    case sigpatches
    case tinfoil

    public var source: SwitchResouceSource {
        switch self {
        case .hekate:
            .github(
                .init(string: "https://api.github.com/repos/CTCaer/hekate/releases/latest")!,
                assetPrefix: "hekate_ctcaer_"
            )
        case .atmosphere:
            .github(
                .init(string: "https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest")!,
                assetPrefix: "atmosphere-"
            )
        case .sigpatches:
            .link(
                .init(string: "https://sigmapatches.coomer.party/sigpatches.zip")!,
                version: "16.1.0"
            )
        case .tinfoil:
            .github(
                .init(string: "https://api.github.com/repos/kkkkyue/Tinfoil/releases/latest")!,
                assetPrefix: "Tinfoil.Self.Installer"
            )
        }
    }

    var assetFileName: String {
        switch self {
        case .hekate:
            "hekate.zip"
        case .atmosphere:
            "atmosphere.zip"
        case .sigpatches:
            "sigpatches.zip"
        case .tinfoil:
            "tinfoil.zip"
        }
    }
}

extension SwitchResource {
    private var fileManager: FileManager {
        .default
    }

    func handleAsset(
        at location: URL,
        destination: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws {
        let (location, destination) = switch self {
        case .hekate:
            (location.appending(path: "bootloader"), destination.appending(path: "bootloader"))

        case .atmosphere, .sigpatches, .tinfoil:
            (location, destination)
        }

        fileManager.merge(
            atPath: location.path(),
            toPath: destination.path(),
            progressSubject: progressSubject
        )
    }
}
