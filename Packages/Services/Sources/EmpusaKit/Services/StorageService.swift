import Combine
import Foundation
import Zip
import OSLog

public protocol StorageServiceProtocol {
    func listStorages() throws -> [ExternalStorage]
    func saveFile(data: Data, fileName: String) async throws -> URL
    func unzipFile(at location: URL, progressSubject: CurrentValueSubject<Double, Never>) throws -> URL
    func removeItem(at path: URL)
}

final public class StorageService: StorageServiceProtocol {
    private let fileManager = FileManager.default
    private let tempDirectoryPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa.Services", category: "StorageService")

    public init() {}

    public func listStorages() throws -> [ExternalStorage] {
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

                return ExternalStorage(
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

    public func removeItem(at path: URL) {
        do {
            try fileManager.removeItem(at: path)
        } catch {
            logger.error("StorageService: \(error.localizedDescription)")
        }
    }
}
