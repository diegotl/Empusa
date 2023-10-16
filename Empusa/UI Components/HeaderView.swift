import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(.logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()

            Text("εmpusa")
                .foregroundStyle(.white)
                .font(.largeTitle)
                .bold()

            Spacer()
        }
        .background(.logoBg)
        .frame(height: 80)
    }
}

#Preview {
    HeaderView()
}
