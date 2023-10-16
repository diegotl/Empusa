import Combine
import EmpusaKit
import OSLog

@MainActor
final class EmpusaModel: ObservableObject {
    // MARK: - Public variables
    @Published var externalStorages: [ExternalStorage] = []
    @Published var selectedExternalStorage: ExternalStorage = .none

    @Published var availableResources: [SwitchResource] = SwitchResource.allCases
    @Published var selectedResources: [SwitchResource] = SwitchResource.allCases

    @Published var isProcessing: Bool = false
    @Published var progress: ProgressData?
    @Published var error: Error?

    var canStartProcess: Bool {
        selectedExternalStorage != .none && !selectedResources.isEmpty && !isProcessing
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
            self.error = error
        }
    }

    func execute() {
        guard selectedExternalStorage != .none else { return }

        Task(priority: .background) { [weak self] in
            guard let self else { return }
            isProcessing = true

            let progressSubject = CurrentValueSubject<ProgressData?, Never>(nil)
            let progressCancellable = progressSubject
                .receive(on: RunLoop.main)
                .sink { progressData in
                    self.progress = progressData
                }

            do {
                try await contentManager.download(
                    resources: selectedResources,
                    into: selectedExternalStorage.url,
                    progressSubject: progressSubject
                )
            } catch {
                self.error = error
            }

            self.progress = nil
            isProcessing = false
            progressCancellable.cancel()
        }
    }

    private func report(progressData: ProgressData) {
        Task { @MainActor in
            self.progress = progressData
        }
    }
}
