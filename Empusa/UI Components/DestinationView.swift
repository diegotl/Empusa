import SwiftUI

struct DestinationView: View {
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

                    Button(action: {
                        model.loadExternalVolumes()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }

                Divider()

                VStack(alignment: .center) {
                    Button("Backup SD Card") {
                        model.backup()
                    }

                    Button("Restore SD Card") {
                        model.isImporting = true
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
        .fileExporter(
            isPresented: $model.isExporting,
            document: model.exportingFile,
            contentType: .zip,
            defaultFilename: "backup.zip",
            onCompletion: model.exportCompletion
        )
        .fileImporter(
            isPresented: $model.isImporting,
            allowedContentTypes: [.zip],
            onCompletion: model.importCompletion
        )
    }
}

#Preview {
    DestinationView(
        model: EmpusaModel()
    )
}
