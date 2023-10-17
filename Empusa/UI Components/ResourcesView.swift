import SwiftUI

struct ResourcesView: View {
    @ObservedObject var model: EmpusaModel

    var body: some View {
        GroupBox("Resources") {
            VStack(alignment: .leading) {
                ForEach(model.availableResources, id: \.self) { resource in
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
}

#Preview {
    ResourcesView(
        model: EmpusaModel()
    )
}
