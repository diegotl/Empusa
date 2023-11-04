import SwiftUI
import Combine
import EmpusaKit
import OSLog

struct AlertData {
    let title: String
    let message: String

    init(error: Error) {
        title = "Error"
        message = error.localizedDescription
    }

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

@MainActor
final class EmpusaModel: ObservableObject {
    // MARK: - Public variables
    @Published var externalVolumes: [ExternalVolume] = []
    @Published var selectedVolume: ExternalVolume = .none

    @Published var isLoadingResources: Bool = false
    @Published var availableResources: [CategoryData] = []
    @Published var selectedResources: [ResourceData] = []

    @Published var isProcessing: Bool = false
    @Published var progress: ProgressData?

    @Published var isPresentingAlert: Bool = false
    @Published var alertData: AlertData? {
        didSet {
            isPresentingAlert = alertData != nil
        }
    }

    @AppStorage("preferPreReleaseVersions") var preferPreRelease = false {
        didSet {
            loadResourcesVersions()
        }
    }

    var validVolumeSelected: Bool {
        selectedVolume != .none
    }

    var canStartProcess: Bool {
        validVolumeSelected && !selectedResources.isEmpty && !isProcessing
    }

    var isAllSelected: Bool {
        get {
            availableResources
                .flatMap { $0.resources }
                .allSatisfy { selectedResources.contains($0) }
        } set {
            switch newValue {
            case true:
                selectedResources = availableResources
                    .flatMap { $0.resources }
            case false:
                selectedResources = []
            }
        }
    }

    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol = StorageService()
    private let assetService: AssetServiceProtocol = AssetService()
    private let resourceService: ResourceServiceProtocol = ResourceService()
    private let contentManager: ContentManagerProtocol = ContentManager()
    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa", category: "EmpusaModel")

    // MARK: - Init
    init() {
        loadExternalVolumes()
    }

    // MARK: - Public functions
    func loadExternalVolumes() {
        storageService
            .externalVolumes
            .map { [weak self] volumes in
                guard let self else { return volumes }

                if selectedVolume == .none || !volumes.contains(selectedVolume) {
                    selectedVolume = volumes.last ?? .none
                }

                return volumes
            }
            .assign(to: &$externalVolumes)
    }

    func execute() {
        guard validVolumeSelected else { return }

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            isProcessing = true

            let progressSubject = CurrentValueSubject<ProgressData?, Never>(nil)
            progressSubject
                .receive(on: RunLoop.main)
                .assign(to: &$progress)

            let result = await contentManager.download(
                resources: selectedResources,
                into: selectedVolume,
                progressSubject: progressSubject
            )

            isProcessing = false
            self.progress = nil
            loadResourcesVersions()

            if !result.failedResources.isEmpty {
                let rateLimitExceeded = result.failedResources.contains { failedResource in
                    if case ClientError.rateLimitExceeded = failedResource.error {
                        return true
                    }
                    return false
                }

                if rateLimitExceeded {
                    alertData = .init(
                        title: "Alert",
                        message: "You've exceeded GitHub's rate limit. Connect to a VPN or wait few hours and try again. The resources that failed to install are: \(result.failedResourceNames)."
                    )
                } else {
                    alertData = .init(
                        title: "Alert",
                        message: "Failed to install \(result.failedResourceNames):\n\n\(result.failedResources.last!.error.localizedDescription)"
                    )
                }
            } else {
                alertData = .init(
                    title: "Success",
                    message: "Selected resources have been downloaded into the selected destination."
                )
            }
        }
    }

    func format() {
        guard validVolumeSelected else { return }

        Task { [weak self] in
            guard let self else { return }

            do {
                try await storageService.format(volume: selectedVolume)
                alertData = .init(
                    title: "Success",
                    message: "Sucessfully formatted the selected volume"
                )
            } catch {
                alertData = .init(error: error)
            }
        }
    }

    func loadResourcesVersions() {
        Task { [weak self] in
            guard let self else { return }
            isLoadingResources = true

            availableResources = try await resourceService
                .fetchResources()

            preSelect()

            isLoadingResources = false
        }
    }

    func preSelect() {
        selectedResources = []
        guard let log = storageService.getLog(at: selectedVolume) else { return }

        selectedResources = availableResources
            .flatMap { $0.resources }
            .filter { resource in
                let release = if preferPreRelease {
                    resource.preRelease ?? resource.stableRelease
                } else {
                    resource.stableRelease
                }

                guard
                    let installedVersion = log.installedVersion(resource),
                    let releaseVersion = release.version else {
                    return false
                }

                return releaseVersion.isHigherThan(installedVersion)
            }
    }
}
