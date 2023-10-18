import Combine
import Foundation

public protocol ContentManagerProtocol {
    func download(resources: [SwitchResource], into destination: URL, progressSubject: CurrentValueSubject<ProgressData?, Never>) async throws
    func backupVolume(at location: URL, progressSubject: CurrentValueSubject<ProgressData?, Never>) async throws -> ZipFile
    func restoreBackup(at location: URL, to destination: URL, progressSubject: CurrentValueSubject<ProgressData?, Never>) async throws
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
            ).map { (title, downloadProgress, unzipProgress, mergeProgress) in
                ProgressData(
                    title: title,
                    progress: accumulatedProgress + downloadProgress + unzipProgress + mergeProgress,
                    total: totalProgress
                )
            }.assign(to: \.value, on: progressSubject)

            // Download asset
            progressTitleSubject.send("Downloading \(resource.assetFileName)...")
            let assetFileTempUrl = try await githubService.downloadAsset(
                for: resource,
                progressSubject: downloadProgressSubject
            )

            // Rename asset file
            let assetFileUrl = assetFileTempUrl
                .deletingLastPathComponent()
                .appending(component: resource.assetFileName)

            try storageService.moveItem(
                at: assetFileTempUrl,
                to: assetFileUrl
            )

            let extractedUrl = try {
                if resource.isAssetZipped {
                    // Unzip asset
                    progressTitleSubject.send("Unzipping \(resource.assetFileName)...")
                    return try storageService.unzipFile(
                        at: assetFileUrl,
                        progressSubject: unzipProgressSubject
                    )
                } else {
                    // Do nothing
                    unzipProgressSubject.send(1)
                    return assetFileUrl
                }
            }()

            // Copy asset to SD
            progressTitleSubject.send("Copying contents of \(resource.assetFileName) into destination...")
            try resource.handleAsset(
                at: extractedUrl,
                destination: destination,
                progressSubject: mergeProgressSubject
            )

            // Delete downloaded files on disk
            progressTitleSubject.send("Removing temporary files...")
            storageService.removeItem(at: assetFileUrl)
            storageService.removeItem(at: extractedUrl)

            cancellable.cancel()
        }
    }

    public func backupVolume(
        at location: URL,
        progressSubject: CurrentValueSubject<ProgressData?, Never>
    ) async throws -> ZipFile {
        let zipProgressSubject = CurrentValueSubject<Double, Never>(0)

        let cancellable = zipProgressSubject.map { zipProgress in
            ProgressData(
                title: "Zipping volume contents...",
                progress: zipProgress,
                total: 1
            )
        }
        .assign(to: \.value, on: progressSubject)

        defer {
            cancellable.cancel()
        }

        return try storageService.zipDirectory(at: location, progressSubject: zipProgressSubject)
    }

    public func restoreBackup(
        at location: URL,
        to destination: URL,
        progressSubject: CurrentValueSubject<ProgressData?, Never>
    ) async throws {
        let unzipProgressSubject = CurrentValueSubject<Double, Never>(0)

        let cancellable = unzipProgressSubject.map { zipProgress in
            ProgressData(
                title: "Restoring backup...",
                progress: zipProgress,
                total: 1
            )
        }
        .assign(to: \.value, on: progressSubject)

        defer {
            cancellable.cancel()
        }

        try storageService.unzipFile(at: location, to: destination, progressSubject: unzipProgressSubject)
    }
}
