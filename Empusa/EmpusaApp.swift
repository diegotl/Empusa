import SwiftUI

@main
struct EmpusaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                model: EmpusaModel()
            )
//            .frame(width: 680, height: 500)
        }
        .windowResizability(.contentMinSize)
    }
}
