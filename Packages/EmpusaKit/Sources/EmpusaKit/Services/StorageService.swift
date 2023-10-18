import Combine
import Foundation
import Zip
import OSLog

public protocol StorageServiceProtocol {
    func listExternalVolumes() throws -> [ExternalVolume]
    func saveFile(data: Data, fileName: String) async throws -> URL
    func unzipFile(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> URL
    func unzipFile(at location: URL, to destination: URL, progressSubject: CurrentValueSubject<Double, Never>) throws
    func removeItem(at path: URL)
    func zipDirectory(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> ZipFile
}

final public class StorageService: StorageServiceProtocol {
    private let fileManager = FileManager.default
    private let tempDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.Services", category: "StorageService")

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

    public func saveFile(data: Data, fileName: String) throws -> URL {
        let destinationPath = tempDirectoryPath.appending(path: fileName)
        try data.write(to: destinationPath)
        return destinationPath
    }

    public func unzipFile(
        at location: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) throws -> URL {
        let fileExtension = location.pathExtension
        let fileName = location.lastPathComponent
        let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        let destination = tempDirectoryPath.appending(path: directoryName)

        try Zip.unzipFile(
            location,
            destination: destination,
            overwrite: true,
            password: nil) { unzipProgress in
                progressSubject.send(unzipProgress)
            }

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

    public func removeItem(at path: URL) {
        do {
            try fileManager.removeItem(at: path)
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
}
