/// Based on https://gist.github.com/alekseypotapov-dev/4d1237adcb97f9f14630e2973406bc46
/// and modified to attend our needs

import Foundation
import OSLog
import Combine

extension FileManager {
    private var logger: Logger {
        .init(subsystem: "nl.trevisa.diego.Empusa.Services", category: "FileManager")
    }

    enum ConflictResolution {
        case keepSource
        case keepDestination
    }

    func moveFile(
        at location: URL,
        to destination: URL,
        progressSubject: CurrentValueSubject<Double, Never>
    ) {
        let fileName = location.lastPathComponent
        let filedestination = destination.appending(path: fileName)

        do {
            try createDirectory(
                at: destination,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            logger.error("Move file error: \(error.localizedDescription)")
        }

        do {
            try removeItem(at: filedestination)
            logger.info("File deleted: \(filedestination)")
        } catch  {}

        do {
            try moveItem(
                at: location,
                to: filedestination
            )
        } catch {
            logger.error("Move file error: \(error.localizedDescription)")
        }

        progressSubject.send(1)
    }

    func merge(
        atPath: String,
        toPath: String,
        conflictResolution: ConflictResolution = .keepSource,
        progressSubject: CurrentValueSubject<Double, Never>
    ) {
        let pathEnumerator = enumerator(atPath: atPath)

        let allObjects = (pathEnumerator?.allObjects as? [String]) ?? []
        var currentObject: Double = 0

        for relativePath in allObjects {
            let subItemAtPath = URL(fileURLWithPath: atPath).appendingPathComponent(relativePath).path
            let subItemToPath = URL(fileURLWithPath: toPath).appendingPathComponent(relativePath).path

            if isDir(atPath: subItemAtPath) {
                if !isDir(atPath: subItemToPath) {
                    do {
                        try createDirectory(atPath: subItemToPath, withIntermediateDirectories: true, attributes: nil)
                        logger.info("Directory created: \(subItemToPath)")
                    }
                    catch {
                        logger.error("Merge: \(error.localizedDescription)")
                    }
                }
                else {
                    logger.info("Directory \(subItemToPath) already exists")
                }
            }
            else {
                if isFile(atPath:subItemToPath) && conflictResolution == .keepSource {
                    do {
                        try removeItem(atPath: subItemToPath)
                        logger.info("File deleted: \(subItemToPath)")
                    }
                    catch {
                        logger.error("Merge: \(error.localizedDescription)")
                    }
                }

                do {
                    try moveItem(atPath: subItemAtPath, toPath: subItemToPath)
                    logger.info("File moved from \(subItemAtPath) to \(subItemToPath)")
                }
                catch {
                    logger.error("Merge: \(error.localizedDescription)")
                }
            }

            currentObject += 1
            progressSubject.send(currentObject / Double(allObjects.count))
        }
    }

    // MARK: - Private functions

    private func isDir(atPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exist = fileExists(atPath: atPath, isDirectory: &isDir)
        return exist && isDir.boolValue
    }

    private func isFile(atPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exist = fileExists(atPath: atPath, isDirectory: &isDir)
        return exist && !isDir.boolValue
    }
}
