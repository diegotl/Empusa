import Foundation
import Combine

// MARK: - DisplayingSwitchResource

public struct DisplayingSwitchResource: Hashable {
    public let resource: SwitchResource
    public let version: String?

    public var formattedName: String {
        [resource.displayName, version]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    public init(resource: SwitchResource, version: String? = nil) {
        self.resource = resource
        self.version = version
    }
}

// MARK: - SwitchResource

public enum SwitchResouceSource {
    case github(URL, assetPrefix: String)
    case forgejo(URL, assetPrefix: String)
    case link(URL, version: String?)
}

public enum SwitchResource: String, CaseIterable {
    case hekate
    case atmosphere
    case sigpatches
    case tinfoil
    case bootLogos
    case lockpickRCM

    public var displayName: String {
        switch self {
        case .hekate:
            "Hekate"
        case .atmosphere:
            "Atmosphère"
        case .sigpatches:
            "Sigpatches"
        case .tinfoil:
            "Tinfoil"
        case .bootLogos:
            "Boot logos"
        case .lockpickRCM:
            "Lockpick RCM"
        }
    }

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
        case .bootLogos:
            .link(
                .init(string: "https://nh-server.github.io/switch-guide/files/bootlogos.zip")!,
                version: nil
            )
        case .lockpickRCM:
            .forgejo(
                .init(string: "https://vps.suchmeme.nl/git/api/v1/repos/mudkip/Lockpick_RCM/releases/latest")!,
                assetPrefix: "Lockpick_RCM.bin"
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
        case .bootLogos:
            "bootlogos.zip"
        case .lockpickRCM:
            "Lockpick_RCM.bin"
        }
    }

    var isAssetZipped: Bool {
        switch self {
        case .lockpickRCM:
            false
        default:
            true
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
        switch self {
        case .hekate, .bootLogos:
            fileManager.merge(
                atPath: location.appending(path: "bootloader").path(),
                toPath: destination.appending(path: "bootloader").path(),
                progressSubject: progressSubject
            )

        case .atmosphere, .sigpatches, .tinfoil:
            fileManager.merge(
                atPath: location.path(),
                toPath: destination.path(),
                progressSubject: progressSubject
            )

        case .lockpickRCM:
            fileManager.moveFile(
                at: location,
                to: destination.appending(path: "bootloader").appending(path: "payloads")
            )
        }
    }
}
