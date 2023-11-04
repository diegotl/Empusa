import SwiftUI

struct ResourcesView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        GroupBox("Resources") {
            VStack(alignment: .leading) {
                if model.isLoadingResources {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List {
                        Toggle(isOn: $model.isAllSelected) {
                            Text("Select all")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(model.availableResources, id: \.self) { category in
                            Section(category.name) {
                                ForEach(category.resources, id: \.self) { resource in
                                    Toggle(isOn: .init(get: {
                                        model.selectedResources.contains(resource)
                                    }, set: { selected in
                                        if selected {
                                            model.selectedResources.append(resource)
                                        } else {
                                            guard let index = model.selectedResources.firstIndex(of: resource) else { return }
                                            model.selectedResources.remove(at: index)
                                        }
                                    })) {
                                        HStack {
                                            Text(resource.formattedName)
                                                .frame(maxWidth: .infinity, alignment: .leading)

                                            if
                                                model.preferPreRelease,
                                                let preRelease = resource.preRelease,
                                                let version = preRelease.version
                                            {
                                                Text(version)
                                            } else if let version = resource.stableRelease.version {
                                                Text(version)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .disabled(model.isProcessing)
        .onAppear(perform: {
            model.loadResourcesVersions()
        })
        .onChange(of: model.selectedVolume) { _ in
            model.loadResourcesVersions()
        }
    }
}

#Preview {
    ResourcesView(
        model: EmpusaModel()
    )
}
