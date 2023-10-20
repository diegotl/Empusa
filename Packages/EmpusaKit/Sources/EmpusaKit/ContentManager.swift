import Combine
import Foundation
import OSLog

public struct FailedResource {
    let resource: SwitchResource
    public let error: Error
}

public struct ProcessResult {
    public var succeededResources: [SwitchResource] = []
    public var failedResources: [FailedResource] = []

    public var failedResourceNames: String {
        failedResources
            .map { $0.resource.displayName }
            .joined(separator: ", ")
    }
}

public protocol ContentManagerProtocol {
    func download(resources: [SwitchResource], into volume: ExternalVolume, progressSubject: CurrentValueSubject<ProgressData?, Never>) async -> ProcessResult
    func backupVolume(at location: URL, progressSubject: CurrentValueSubject<ProgressData?, Never>) async throws -> ZipFile
    func restoreBackup(at location: URL, to destination: URL, progressSubject: CurrentValueSubject<ProgressData?, Never>) async throws
}

public final class ContentManager: ContentManagerProtocol {
    private let storageService: StorageServiceProtocol = StorageService()
    private let githubService: AssetServiceProtocol = AssetService()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "ContentManager")

    public init() {}

    public func download(
        resources: [SwitchResource],
        into volume: ExternalVolume,
        progressSubject: CurrentValueSubject<ProgressData?, Never>
    ) async -> ProcessResult {
        let totalProgress = Double(resources.count) * 3
        let log: EmpusaLog = storageService.getLog(at: volume) ?? .init()
        var result = ProcessResult()

        for resource in resources {
            do {
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
                let asset = try await githubService.downloadAsset(
                    for: resource,
                    progressSubject: downloadProgressSubject
                )
                
                // Rename asset file
                let assetFileUrl = asset
                    .url
                    .deletingLastPathComponent()
                    .appending(component: resource.assetFileName)
                
                try storageService.moveItem(
                    at: asset.url,
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
                    destination: volume.url,
                    progressSubject: mergeProgressSubject
                )
                
                // Delete downloaded files on disk
                progressTitleSubject.send("Removing temporary files...")
                storageService.removeItem(at: assetFileUrl)
                storageService.removeItem(at: extractedUrl)
                
                // Update log
                log.add(
                    resource: resource,
                    version: asset.version
                )

                result.succeededResources.append(resource)
                cancellable.cancel()
            } catch {
                result.failedResources.append(.init(
                    resource: resource,
                    error: error
                ))
                logger.error("Fail to execute for resource \(resource.displayName): \(error.localizedDescription)")
            }
        }

        // Save log file
        storageService.saveLog(
            log,
            at: volume
        )

        return result
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
