import SwiftUI
import EmpusaMacros

struct SettingsView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    "Prefer pre-releases over stable versions",
                    isOn: $model.preferPreRelease
                )

                Divider()

                HStack(spacing: 12) {
                    Image(.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("εmpusa")
                            .font(.title) +
                        Text(" \(NSApplication.appVersion)")
                            .font(.title3)

                        HStack {
                            Text("Developed by diegotrevisan")
                                .font(.subheadline)

                            Divider()

                            Link(destination: #URL("http://github.com/diegotl/Empusa"), label: {
                                Text("Project's page")
                                    .font(.subheadline)
                            })
                        }
                        .frame(height: 20)
                    }
                }
            }
        }
        .padding(20)
    }
}


#Preview {
    SettingsView(
        model: EmpusaModel()
    )
}
