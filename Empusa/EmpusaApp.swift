import SwiftUI
import Sparkle

@main
struct EmpusaApp: App {
    private let updaterController: SPUStandardUpdaterController = .init(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        WindowGroup {
            MainView(
                model: EmpusaModel()
            )
            .frame(width: 680, height: 420)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
