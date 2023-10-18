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
    case hekateIPL
    case atmosphere
    case fusee
    case sigpatches
    case tinfoil
    case bootLogos
    case lockpickRCM
    case hbAppStore

    public var displayName: String {
        switch self {
        case .hekate:
            "Hekate"
        case .hekateIPL:
            "hekate_ipl.ini"
        case .atmosphere:
            "Atmosphère"
        case .fusee:
            "Fusée"
        case .sigpatches:
            "Sigpatches"
        case .tinfoil:
            "Tinfoil"
        case .bootLogos:
            "Boot logos"
        case .lockpickRCM:
            "Lockpick RCM"
        case .hbAppStore:
            "HB App Store"
        }
    }

    public var source: SwitchResouceSource {
        switch self {
        case .hekate:
            .github(
                .init(string: "https://api.github.com/repos/CTCaer/hekate/releases/latest")!,
                assetPrefix: "hekate_ctcaer_"
            )
        case .hekateIPL:
            .link(
                .init(string: "https://nh-server.github.io/switch-guide/files/emu/hekate_ipl.ini")!,
                version: "(from NH Switch Guide)"
            )
        case .atmosphere:
            .github(
                .init(string: "https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest")!,
                assetPrefix: "atmosphere-"
            )
        case .fusee:
            .github(
                .init(string: "https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest")!,
                assetPrefix: "fusee.bin"
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
                version: "(from NH Switch Guide)"
            )
        case .lockpickRCM:
            .forgejo(
                .init(string: "https://vps.suchmeme.nl/git/api/v1/repos/mudkip/Lockpick_RCM/releases/latest")!,
                assetPrefix: "Lockpick_RCM.bin"
            )
        case .hbAppStore:
            .github(
                .init(string: "https://api.github.com/repos/fortheusers/hb-appstore/releases/latest")!,
                assetPrefix: "appstore.nro"
            )
        }
    }

    var assetFileName: String {
        switch self {
        case .hekate:
            "hekate.zip"
        case .hekateIPL:
            "hekate_ipl.ini"
        case .atmosphere:
            "atmosphere.zip"
        case .fusee:
            "fusee.bin"
        case .sigpatches:
            "sigpatches.zip"
        case .tinfoil:
            "tinfoil.zip"
        case .bootLogos:
            "bootlogos.zip"
        case .lockpickRCM:
            "Lockpick_RCM.bin"
        case .hbAppStore:
            "appstore.nro"
        }
    }

    var isAssetZipped: Bool {
        switch self {
        case .hekateIPL, .lockpickRCM, .hbAppStore, .fusee:
            false
        default:
            true
        }
    }
}
