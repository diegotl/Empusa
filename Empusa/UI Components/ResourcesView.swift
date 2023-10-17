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
                        ForEach(model.availableResources, id: \.self) { displayingResource in
                            Toggle(isOn: .init(get: {
                                model.selectedResources.contains(displayingResource.resource)
                            }, set: { selected in
                                if selected {
                                    model.selectedResources.append(displayingResource.resource)
                                } else {
                                    guard let index = model.selectedResources.firstIndex(of: displayingResource.resource) else { return }
                                    model.selectedResources.remove(at: index)
                                }
                            })) {
                                Text(displayingResource.formattedName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .disabled(model.isProcessing)
    }
}

#Preview {
    ResourcesView(
        model: EmpusaModel()
    )
}
