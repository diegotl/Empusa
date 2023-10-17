import SwiftUI

struct DestinationView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        GroupBox("Destination") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Picker(selection: $model.selectedExternalStorage) {
                        ForEach(model.externalStorages, id: \.self) { storage in
                            if storage == .none {
                                Text(storage.name)
                            } else {
                                Text("\(storage.name) (\(storage.formattedCapacity))")
                            }
                        }
                    } label: {
                        EmptyView()
                    }

                    Button(action: {
                        model.loadExternalStorages()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }

                Divider()

                VStack(alignment: .center) {
                    Button("Backup SD Card") {
                        model.backup()
                    }

                    Button("Restore SD Card") {}
                }
                .frame(maxWidth: .infinity)

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
            onCompletion: model.backupCompletion
        )
    }
}

#Preview {
    DestinationView(
        model: EmpusaModel()
    )
}
