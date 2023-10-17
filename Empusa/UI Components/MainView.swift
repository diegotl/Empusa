import SwiftUI
import EmpusaKit

struct MainView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        VStack {
            HeaderView()

            HStack {
                DestinationView(model: model)
                ResourcesView(model: model)
            }
            .padding()

            VStack {
                DataProgressView(model: model)

                HStack {
                    Spacer()

                    Button("Run") {
                        model.execute()
                    }
                    .disabled(!model.canStartProcess)
                }
            }
            .padding()

            Spacer()
        }
        .alert(isPresented: $model.isShowingAlert, content: {
            .init(
                title: Text(model.alertData?.title ?? ""),
                message: Text(model.alertData?.message ?? "")
            )
        })
    }
}

#Preview {
    MainView(
        model: EmpusaModel()
    )
}
