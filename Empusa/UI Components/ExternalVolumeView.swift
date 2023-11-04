import SwiftUI

struct ExternalVolumeView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        GroupBox("Destination") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Picker(selection: $model.selectedVolume) {
                        ForEach(model.externalVolumes, id: \.self) { volume in
                            if volume == .none {
                                Text(volume.name)
                            } else {
                                Text("\(volume.name) (\(volume.formattedCapacity))")
                            }
                        }
                    } label: {
                        EmptyView()
                    }
                }

                Divider()

                VStack(alignment: .center) {
                    Button("Format SD Card") {
                        model.format()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(!model.validVolumeSelected)

                Spacer()
            }
            .padding(4)
        }
        .disabled(model.isProcessing)
        .frame(width: 240)
    }
}

#Preview {
    ExternalVolumeView(
        model: EmpusaModel()
    )
}
