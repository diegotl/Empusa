import SwiftUI

struct DataProgressView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        if let progressData = model.progress {
            ProgressView(
                progressData.title,
                value: progressData.progress,
                total: progressData.total
            )
        }
    }
}

#Preview {
    DataProgressView(
        model: EmpusaModel()
    )
}
