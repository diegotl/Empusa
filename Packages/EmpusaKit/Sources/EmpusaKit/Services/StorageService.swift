import Combine
import Foundation
import Zip
import OSLog
import AppKit

enum StorageServiceError: LocalizedError {
    case formatFailure(String)

    var errorDescription: String? {
        switch self {
        case .formatFailure(let description):
            description
        }
    }
}

public protocol StorageServiceProtocol {
    var externalVolumes: AnyPublisher<[ExternalVolume], Never> { get }

    func unzipFile(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> URL
    func unzipFile(at location: URL, to destination: URL, progressSubject: CurrentValueSubject<Double, Never>) throws
    func moveItem(at location: URL, to destination: URL) throws
    func removeItem(at location: URL)
    func zipDirectory(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> ZipFile
    func format(volume: ExternalVolume) async throws

    func getLog(at volume: ExternalVolume) -> EmpusaLog?
    func saveLog(_ log: EmpusaLog, at volume: ExternalVolume)
}

final public class StorageService: StorageServiceProtocol {
    public var externalVolumes: AnyPublisher<[ExternalVolume], Never> {
        externalVolumesSubject.eraseToAnyPublisher()
    }

    private let externalVolumesSubject = CurrentValueSubject<[ExternalVolume], Never>([])

    private let fileManager = FileManager.default
    private let tempDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "StorageService")
    private let workspace: NSWorkspace = .shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupListeners()
        listExternalVolumes()
    }

    public func unzipFile(
        at location: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws -> URL {
        let fileExtension = location.pathExtension
        let fileName = location.lastPathComponent
        let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        let destination = tempDirectoryPath.appending(path: directoryName)

        try unzipFile(
            at: location,
            to: destination,
            progressSubject: progressSubject
        )

        return destination
    }

    public func unzipFile(
        at location: URL,
        to destination: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws {
        try Zip.unzipFile(
            location,
            destination: destination,
            overwrite: true,
            password: nil
        ) { progress in
            progressSubject.send(progress)
        }
    }

    public func moveItem(
        at location: URL,
        to destination: URL
    ) throws {
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(
            at: location,
            to: destination
        )
    }

    public func removeItem(at location: URL) {
        do {
            try fileManager.removeItem(at: location)
        } catch {
            logger.error("StorageService: \(error.localizedDescription)")
        }
    }

    public func zipDirectory(
        at location: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws -> ZipFile {
        let paths = try fileManager
            .contentsOfDirectory(
                at: location,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

        let destinationPath = tempDirectoryPath
            .appending(component: "backup.zip")

        try Zip.zipFiles(
            paths: paths,
            zipFilePath: destinationPath,
            password: nil,
            compression: .BestCompression
        ) { progress in
            progressSubject.send(progress)
        }

        return ZipFile(
            url: destinationPath
        )
    }

    public func format(
        volume: ExternalVolume
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let session = DASessionCreate(kCFAllocatorDefault) else {
                logger.error("Failed to create DASession")
                continuation.resume(
                    throwing: StorageServiceError.formatFailure("Failed to create DASession")
                )
                return
            }

            guard let disk = DADiskCreateFromVolumePath(
                kCFAllocatorDefault,
                session,
                volume.url as CFURL
            ) else {
                logger.error("Failed to create DADisk")
                continuation.resume(
                    throwing: StorageServiceError.formatFailure("Failed to create DADisk")
                )
                return
            }

            guard
                let bsdNameChar = DADiskGetBSDName(disk),
                let bsdName = String(validatingUTF8: bsdNameChar) else {
                logger.error("Failed to get BSDName")
                continuation.resume(
                    throwing: StorageServiceError.formatFailure("Failed to get BSDName")
                )
                return
            }

            let task = Process()
            let volumeName = "SWITCH SD"
            task.launchPath = "/usr/sbin/diskutil"
            task.arguments = ["eraseVolume", "fat32", volumeName, bsdName]

            let outputPipe = Pipe()
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            task.standardOutput = outputPipe

            let errorPipe = Pipe()
            errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            task.standardError = errorPipe

            task.terminationHandler = { _ in
                let error = String(
                    data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                )

                if let error, !error.isEmpty {
                    continuation.resume(
                        throwing: StorageServiceError.formatFailure(error)
                    )
                } else {
                    continuation.resume()
                }
            }

            task.launch()
        }
    }

    public func getLog(at volume: ExternalVolume) -> EmpusaLog? {
        do {
            let logUrl = volume.url.appending(component: "empusa.log")
            let logData = try Data(contentsOf: logUrl)
            return try JSONDecoder().decode(EmpusaLog.self, from: logData)
        } catch {
            logger.error("Could not load log file in volume: \(error.localizedDescription)")
            return nil
        }
    }

    public func saveLog(_ log: EmpusaLog, at volume: ExternalVolume) {
        do {
            let logUrl = volume.url.appending(component: "empusa.log")
            let logData = try JSONEncoder().encode(log)
            try logData.write(to: logUrl)
        } catch {
            logger.error("Could not save log file in volume: \(error.localizedDescription)")
        }
    }

    // MARK: - Private functions

    private func listExternalVolumes() {
        let volumeUrls: [URL] = (fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil) ?? [])
            .filter { $0.pathComponents.count > 1 }
            .filter { $0.pathComponents[1] == "Volumes" }
            .compactMap { $0 }

        let fetchedVolumes: [ExternalVolume] = volumeUrls.compactMap { volumeUrl in
            let volumeIcon = workspace
                .icon(forFile: volumeUrl.path)
                .tiffRepresentation

            let resourceValues = try? volumeUrl.resourceValues(
                forKeys: [
                    .volumeUUIDStringKey,
                    .nameKey,
                    .pathKey,
                    .volumeIsRemovableKey,
                    .volumeTotalCapacityKey
                ]
            )

            guard
                let volumeIsRemovable = resourceValues?.volumeIsRemovable,
                volumeIsRemovable,
                let uuid = resourceValues?.volumeUUIDString,
                let name = resourceValues?.name,
                let path = resourceValues?.path,
                let capacity = resourceValues?.volumeTotalCapacity
            else {
                return nil
            }

            return ExternalVolume(
                id: uuid,
                name: name,
                icon: volumeIcon,
                path: path,
                capacity: Int64(capacity)
            )
        }

        externalVolumesSubject.send(fetchedVolumes)
    }

    private func setupListeners() {
        let mountNotification = workspace
            .notificationCenter
            .publisher(for: NSWorkspace.didMountNotification)

        let unmountNotification = workspace
            .notificationCenter
            .publisher(for: NSWorkspace.didUnmountNotification)

        let renameNotification = workspace
            .notificationCenter
            .publisher(for: NSWorkspace.didRenameVolumeNotification)
            .debounce(for: 1, scheduler: RunLoop.main)

        Publishers.Merge3(
            mountNotification,
            unmountNotification,
            renameNotification
        ).sink { [weak self] _ in
            self?.listExternalVolumes()
        }.store(in: &cancellables)
    }
}

// MARK: - SwitchResource extensions

extension ReleaseData {
    private var fileManager: FileManager {
        .default
    }

    func install(
        at location: URL,
        destination: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws {
        for installStep in installSteps {
            switch installStep.operation {
            case .mergeAll:
                fileManager.merge(
                    from: location,
                    to: destination,
                    progressSubject: progressSubject
                )

            case .moveFile:
                fileManager.moveFile(
                    at: location.appending(path: installStep.origin!),
                    to: destination.appending(path: installStep.destination!),
                    progressSubject: progressSubject
                )

            case .mergeDir:
                fileManager.merge(
                    from: location.appending(path: installStep.origin!),
                    to: destination.appending(path: installStep.destination!),
                    progressSubject: progressSubject
                )
            }
        }
    }
}
