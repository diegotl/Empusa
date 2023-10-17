import Foundation
import Combine

enum SwitchResouceSource {
    case github(URL, assetPrefix: String)
    case link(URL)
}

public enum SwitchResource: String, CaseIterable {
    case hekate
    case atmosphere
    case sigpatches
    case tilfoil

    var source: SwitchResouceSource {
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
            .link(.init(string: "https://sigmapatches.coomer.party/sigpatches.zip")!)
        case .tilfoil:
            .link(.init(string: "https://tinfoil.media/repo/Tinfoil%20Self%20Installer%20%5B050000BADDAD0000%5D%5B16.0%5D%5Bv2%5D.zip")!)
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
        case .tilfoil:
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
        switch self {
        case .hekate:
            let contentPaths = try fileManager.contentsOfDirectory(atPath: location.path())
            guard let bootloaderPath = contentPaths.first(where: { $0 == "bootloader" }) else { return }

            fileManager.merge(
                atPath: location.appending(path: bootloaderPath).path(),
                toPath: destination.appending(path: bootloaderPath).path(),
                progressSubject: progressSubject
            )

        case .atmosphere, .sigpatches, .tilfoil:
            fileManager.merge(
                atPath: location.path(),
                toPath: destination.path(),
                progressSubject: progressSubject
            )
        }
    }
}
