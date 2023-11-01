import Combine
import Foundation
import Zip
import OSLog

public protocol StorageServiceProtocol {
    func listExternalVolumes() throws -> [ExternalVolume]
    func unzipFile(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> URL
    func unzipFile(at location: URL, to destination: URL, progressSubject: CurrentValueSubject<Double, Never>) throws
    func moveItem(at location: URL, to destination: URL) throws
    func removeItem(at location: URL)
    func zipDirectory(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> ZipFile

    func getLog(at volume: ExternalVolume) -> EmpusaLog?
    func saveLog(_ log: EmpusaLog, at volume: ExternalVolume)
}

final public class StorageService: StorageServiceProtocol {
    private let fileManager = FileManager.default
    private let tempDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.EmpusaKit", category: "StorageService")

    public init() {}

    public func listExternalVolumes() throws -> [ExternalVolume] {
        try fileManager.contentsOfDirectory(
            at: URL(fileURLWithPath: "/Volumes"),
            includingPropertiesForKeys: nil
        ).compactMap { volumeUrl in
            do {
                let resourceValues = try volumeUrl.resourceValues(
                    forKeys: [
                        .volumeUUIDStringKey,
                        .nameKey,
                        .pathKey,
                        .volumeIsRemovableKey,
                        .volumeTotalCapacityKey
                    ]
                )

                guard
                    let volumeIsRemovable = resourceValues.volumeIsRemovable,
                    volumeIsRemovable,
                    let uuid = resourceValues.volumeUUIDString,
                    let name = resourceValues.name,
                    let path = resourceValues.path,
                    let capacity = resourceValues.volumeTotalCapacity
                else {
                    return nil
                }

                return ExternalVolume(
                    id: uuid,
                    name: name,
                    path: path,
                    capacity: Int64(capacity)
                )
            } catch {
                return nil
            }
        }
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
