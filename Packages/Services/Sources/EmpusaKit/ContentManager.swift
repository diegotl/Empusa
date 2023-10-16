import Combine
import Foundation

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
            .link(.init(string: "https://tinfoil.media/repo/Tinfoil Self Installer [050000BADDAD0000][16.0][v2].zip")!)
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

public struct ProgressData {
    public let title: String
    public let progress: Double
    public let total: Double
}

public enum ContentManagerError: Error {
    
}

public protocol ContentManagerProtocol {
    func download(
        resources: [SwitchResource],
        into destination: URL,
        progressSubject: CurrentValueSubject<ProgressData?, Never>
    ) async throws
}

public final class ContentManager: ContentManagerProtocol {
    private let storageService: StorageServiceProtocol = StorageService()
    private let githubService: AssetServiceProtocol = AssetService()

    public init() {}

    public func download(
        resources: [SwitchResource],
        into destination: URL,
        progressSubject: CurrentValueSubject<ProgressData?, Never>
    ) async throws {
        let totalProgress = Double(resources.count) * 3

        for resource in resources {
            let accumulatedProgress = 3 * Double(resources.firstIndex(of: resource)!)
            let progressTitleSubject = CurrentValueSubject<String, Never>("")
            let downloadProgressSubject = CurrentValueSubject<Double, Never>(0)
            let unzipProgressSubject = CurrentValueSubject<Double, Never>(0)
            let mergeProgressSubject = CurrentValueSubject<Double, Never>(0)

            let cancellable = Publishers.CombineLatest4(
                progressTitleSubject,
                downloadProgressSubject,
                unzipProgressSubject,
                mergeProgressSubject
            ).sink { (title, downloadProgress, unzipProgress, mergeProgress) in
                progressSubject.send(.init(
                    title: title,
                    progress: accumulatedProgress + downloadProgress + unzipProgress + mergeProgress,
                    total: totalProgress
                ))
            }

            // Download asset
            progressTitleSubject.send("Downloading \(resource.assetFileName)...")
            let asset = try await githubService.downloadAsset(
                for: resource,
                progressSubject: downloadProgressSubject
            )

            progressTitleSubject.send("Saving \(resource.assetFileName)...")
            let assetFilePath = try await storageService.saveFile(
                data: asset,
                fileName: resource.assetFileName
            )

            // Unzip asset
            progressTitleSubject.send("Unzipping \(resource.assetFileName)...")
            let extractedPath = try storageService.unzipFile(
                at: assetFilePath,
                progressSubject: unzipProgressSubject
            )

            // Copy asset to SD
            progressTitleSubject.send("Copying contents of \(resource.assetFileName) into destination...")
            try resource.handleAsset(
                at: extractedPath,
                destination: destination,
                progressSubject: mergeProgressSubject
            )

            // Delete downloaded files on disk
            progressTitleSubject.send("Removing temporary files...")
            storageService.removeItem(at: assetFilePath)
            storageService.removeItem(at: extractedPath)

            cancellable.cancel()
        }
    }
}
