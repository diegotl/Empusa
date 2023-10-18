import SwiftUI

@main
struct EmpusaApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(
                model: EmpusaModel()
            )
            .frame(width: 680, height: 420)
        }
        .windowResizability(.contentSize)
    }
}
