import SwiftUI
import EmpusaKit

struct ContentView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        VStack {
            HeaderView()

            HStack {
                GroupBox("Destination") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Picker(selection: $model.selectedExternalStorage) {
                                ForEach(model.externalStorages, id: \.self) { storage in
                                    Text(storage.name)
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

                        if model.selectedExternalStorage != .none {
                            Text(model.selectedExternalStorage.formattedCapacity)
                        }

                        Divider()

                        VStack(alignment: .center) {
                            Button("Backup SD Card") {}
                            Button("Restore SD Card") {}
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                    }
                    .padding(4)
                }
                .disabled(model.isProcessing)
                .frame(width: 240)

                GroupBox("Resources") {
                    VStack(alignment: .leading) {
                        ForEach(model.availableResources, id: \.self) { resource in
                            Toggle(isOn: .init(get: {
                                model.selectedResources.contains(resource)
                            }, set: { selected in
                                if selected {
                                    model.selectedResources.append(resource)
                                } else {
                                    guard let index = model.selectedResources.firstIndex(of: resource) else {
                                        return
                                    }
                                    model.selectedResources.remove(at: index)
                                }
                            })) {
                                Text(resource.rawValue.capitalized)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Spacer()
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                }
                .disabled(model.isProcessing)
            }
            .padding()

            VStack {
                if let progressData = model.progress {
                    ProgressView(
                        progressData.title,
                        value: progressData.progress,
                        total: progressData.total
                    )
                }

                HStack {
                    Spacer()

                    Button("Download") {
                        model.execute()
                    }
                    .disabled(!model.canStartProcess)
                }
            }
            .padding()

            Spacer()
        }
    }
}

#Preview {
    ContentView(
        model: EmpusaModel()
    )
}
