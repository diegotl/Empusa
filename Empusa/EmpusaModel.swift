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
}

@MainActor
final class EmpusaModel: ObservableObject {
    // MARK: - Public variables
    @Published var externalStorages: [ExternalStorage] = []
    @Published var selectedExternalStorage: ExternalStorage = .none

    @Published var availableResources: [SwitchResource] = SwitchResource.allCases
    @Published var selectedResources: [SwitchResource] = SwitchResource.allCases

    @Published var isExporting: Bool = false
    @Published var exportingFile: ZipFile?

    @Published var isProcessing: Bool = false
    @Published var progress: ProgressData?

    @Published var isShowingAlert: Bool = false
    @Published var alertData: AlertData? {
        didSet {
            isShowingAlert = alertData != nil
        }
    }

    var canStartProcess: Bool {
        selectedExternalStorage != .none && !selectedResources.isEmpty && !isProcessing && !isExporting
    }

    lazy var backupCompletion: ((Result<URL, Error>) -> Void) = { [weak self] result in
        self?.exportingFile = nil
        self?.isExporting = false
    }

    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol = StorageService()
    let contentManager: ContentManagerProtocol = ContentManager()

    private let logger: Logger = .init(subsystem: "nl.trevisa.diego.Empusa", category: "EmpusaModel")

    // MARK: - Init
    init() {
        loadExternalStorages()
    }

    // MARK: - Public functions
    func loadExternalStorages() {
        do {
            let externalStorages = try storageService.listStorages()
            self.externalStorages = externalStorages

            if selectedExternalStorage == .none || !externalStorages.contains(selectedExternalStorage) {
                selectedExternalStorage = externalStorages.last ?? .none
            }
        } catch {
            logger.error("Failed to load external storages: \(error.localizedDescription)")
            selectedExternalStorage = .none
            alertData = .init(error: error)
        }
    }

    func execute() {
        guard selectedExternalStorage != .none else { return }

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
                    into: selectedExternalStorage.url,
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
        guard selectedExternalStorage != .none else { return }

        Task(priority: .background) { [weak self] in
            guard let self else { return }

            let progressSubject = CurrentValueSubject<ProgressData?, Never>(nil)
            progressSubject
                .receive(on: RunLoop.main)
                .assign(to: &$progress)

            let zipFile = try await contentManager.backupStorage(
                at: selectedExternalStorage.url,
                progressSubject: progressSubject
            )

            exportingFile = zipFile
            isExporting = true
            self.progress = nil
        }
    }

    private func report(progressData: ProgressData) {
        Task { @MainActor in
            self.progress = progressData
        }
    }
}
