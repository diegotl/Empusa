import Foundation
import Combine
import EmpusaMacros

// MARK: - DisplayingSwitchResource

public struct DisplayingSwitchResource: Hashable {
    public let resource: SwitchResource
    public let version: String?
    public let preChecked: Bool

    public var formattedName: String {
        [
            resource.displayName,
            resource.additionalDescription
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

// MARK: - SwitchResource

public enum SwitchResouceSource {
    case github(URL, assetPrefix: String)
    case forgejo(URL, assetPrefix: String)
    case link(URL, version: String?)
}

public enum SwitchResource: String, Codable, CaseIterable {
    case hekate
    case hekateIPL
    case atmosphere
    case fusee
    case sigpatches
    case tinfoil
    case bootLogos
    case emummc
    case lockpickRCM
    case hbAppStore
    case jksv
    case ftpd
    case nxThemesInstaller
    case nxShell
    case goldleaf

    public var displayName: String {
        switch self {
        case .hekate:               "Hekate"
        case .hekateIPL:            "hekate_ipl.ini"
        case .atmosphere:           "Atmosphère"
        case .fusee:                "Fusée"
        case .sigpatches:           "Sigpatches"
        case .tinfoil:              "Tinfoil"
        case .bootLogos:            "Boot logos"
        case .emummc:               "emummc.txt"
        case .lockpickRCM:          "Lockpick RCM"
        case .hbAppStore:           "HB App Store"
        case .jksv:                 "JKSV"
        case .ftpd:                 "ftpd"
        case .nxThemesInstaller:    "NXThemesInstaller"
        case .nxShell:              "NX-Shell"
        case .goldleaf:             "Goldleaf"
        }
    }

    public var source: SwitchResouceSource {
        switch self {
        case .hekate:
            .github(
                #URL("https://api.github.com/repos/CTCaer/hekate/releases/latest"),
                assetPrefix: "hekate_ctcaer_"
            )
        case .hekateIPL:
            .link(
                #URL("https://nh-server.github.io/switch-guide/files/emu/hekate_ipl.ini"),
                version: nil
            )
        case .atmosphere:
            .github(
                #URL("https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest"),
                assetPrefix: "atmosphere-"
            )
        case .fusee:
            .github(
                #URL("https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest"),
                assetPrefix: "fusee.bin"
            )
        case .sigpatches:
            .link(
                #URL("https://sigmapatches.coomer.party/sigpatches.zip"),
                version: "16.1.0"
            )
        case .tinfoil:
            .github(
                #URL("https://api.github.com/repos/kkkkyue/Tinfoil/releases/latest"),
                assetPrefix: "Tinfoil.Self.Installer"
            )
        case .bootLogos:
            .link(
                #URL("https://nh-server.github.io/switch-guide/files/bootlogos.zip"),
                version: nil
            )
        case .emummc:
            .link(
                #URL("https://nh-server.github.io/switch-guide/files/emummc.txt"),
                version: nil
            )
        case .lockpickRCM:
            .forgejo(
                #URL("https://vps.suchmeme.nl/git/api/v1/repos/mudkip/Lockpick_RCM/releases/latest"),
                assetPrefix: "Lockpick_RCM.bin"
            )
        case .hbAppStore:
            .github(
                #URL("https://api.github.com/repos/fortheusers/hb-appstore/releases/latest"),
                assetPrefix: "appstore.nro"
            )
        case .jksv:
            .github(
                #URL("https://api.github.com/repos/J-D-K/JKSV/releases/latest"),
                assetPrefix: "JKSV.nro"
            )
        case .ftpd:
            .github(
                #URL("https://api.github.com/repos/mtheall/ftpd/releases/latest"),
                assetPrefix: "ftpd.nro"
            )
        case .nxThemesInstaller:
            .github(
                #URL("https://api.github.com/repos/exelix11/SwitchThemeInjector/releases/latest"),
                assetPrefix: "NXThemesInstaller.nro"
            )
        case .nxShell:
            .github(
                #URL("https://api.github.com/repos/joel16/NX-Shell/releases/latest"),
                assetPrefix: "NX-Shell.nro"
            )
        case .goldleaf:
            .github(
                #URL("https://api.github.com/repos/XorTroll/Goldleaf/releases/latest"),
                assetPrefix: "Goldleaf.nro"
            )
        }
    }

    var assetFileName: String {
        switch self {
        case .hekate:               "hekate.zip"
        case .hekateIPL:            "hekate_ipl.ini"
        case .atmosphere:           "atmosphere.zip"
        case .fusee:                "fusee.bin"
        case .sigpatches:           "sigpatches.zip"
        case .tinfoil:              "tinfoil.zip"
        case .bootLogos:            "bootlogos.zip"
        case .emummc:               "emummc.txt"
        case .lockpickRCM:          "Lockpick_RCM.bin"
        case .hbAppStore:           "appstore.nro"
        case .jksv:                 "JKSV.nro"
        case .ftpd:                 "ftpd.nro"
        case .nxThemesInstaller:    "NXThemesInstaller.nro"
        case .nxShell:              "NX-Shell.nro"
        case .goldleaf:             "Goldleaf.nro"
        }
    }

    var additionalDescription: String? {
        switch self {
        case .hekateIPL, .bootLogos, .emummc:
            "(from NH Switch Guide)"
        default:
            nil
        }
    }

    var isAssetZipped: Bool {
        switch self {
        case .hekateIPL, .emummc, .lockpickRCM, .hbAppStore,
             .fusee, .jksv, .ftpd, .nxThemesInstaller,
             .nxShell, .goldleaf:
            false
        default:
            true
        }
    }

    var uncheckedIfInstalled: Bool {
        switch self {
        case .hekateIPL, .bootLogos:
            true
        default:
            false
        }
    }
}
