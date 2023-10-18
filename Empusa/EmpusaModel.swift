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
    @Published var availableResources: [DisplayingSwitchResource] = []
    @Published var selectedResources: [SwitchResource] = SwitchResource.allCases

    @Published var isImporting: Bool = false
    @Published var isExporting: Bool = false
    @Published var exportingFile: ZipFile?

    @Published var isProcessing: Bool = false
    @Published var progress: ProgressData?

    @Published var isPresentingAlert: Bool = false
    @Published var alertData: AlertData? {
        didSet {
            isPresentingAlert = alertData != nil
        }
    }

    var validVolumeSelected: Bool {
        selectedVolume != .none
    }

    var canStartProcess: Bool {
        validVolumeSelected && !selectedResources.isEmpty && !isProcessing && !isExporting
    }

    lazy var exportCompletion: ((Result<URL, Error>) -> Void) = { [weak self] result in
        if let tempZipFilePath = self?.exportingFile?.url {
            self?.storageService.removeItem(at: tempZipFilePath)
        }

        self?.exportingFile = nil
        self?.isExporting = false
    }

    lazy var importCompletion: ((Result<URL, Error>) -> Void) = { [weak self] result in
        switch result {
        case .success(let zipUrl):
            self?.restoreBackup(zipUrl: zipUrl)
        case .failure(let error):
            self?.alertData = .init(error: error)
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
        loadResourcesVersions()
    }

    // MARK: - Public functions
    func loadExternalVolumes() {
        do {
            externalVolumes = try storageService.listExternalVolumes()

            if selectedVolume == .none || !externalVolumes.contains(selectedVolume) {
                selectedVolume = externalVolumes.last ?? .none
            }
        } catch {
            logger.error("Failed to load external volumes: \(error.localizedDescription)")
            selectedVolume = .none
            alertData = .init(error: error)
        }
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

            do {
                try await contentManager.download(
                    resources: selectedResources,
                    into: selectedVolume.url,
                    progressSubject: progressSubject
                )
            } catch {
                alertData = .init(error: error)
            }

            isProcessing = false
            self.progress = nil
        }
    }

    func backup() {
        guard validVolumeSelected else { return }

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            isProcessing = true

            let progressSubject = CurrentValueSubject<ProgressData?, Never>(nil)
            progressSubject
                .receive(on: RunLoop.main)
                .assign(to: &$progress)

            let zipFile = try await contentManager.backupVolume(
                at: selectedVolume.url,
                progressSubject: progressSubject
            )

            isProcessing = false
            exportingFile = zipFile
            isExporting = true
            self.progress = nil
        }
    }

    func restoreBackup(zipUrl: URL) {
        guard validVolumeSelected else { return }
        isProcessing = true

        Task(priority: .background) { [weak self] in
            guard let self else { return }

            let progressSubject = CurrentValueSubject<ProgressData?, Never>(nil)
            progressSubject
                .receive(on: RunLoop.main)
                .assign(to: &$progress)

            try await contentManager
                .restoreBackup(
                    at: zipUrl,
                    to: selectedVolume.url,
                    progressSubject: progressSubject
                )

            isProcessing = false
            self.progress = nil

            self.alertData = .init(
                title: "Success",
                message: "Backup sucessfully restored to the selected volume"
            )
        }
    }

    func loadResourcesVersions() {
        Task { [resourceService, weak self] in
            self?.isLoadingResources = true
            self?.availableResources = await resourceService.fetchResources()
            self?.isLoadingResources = false
        }
    }
}
