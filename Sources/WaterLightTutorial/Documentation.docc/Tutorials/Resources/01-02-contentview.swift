import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("WaterLight")
                .font(.largeTitle)

            Button(isOpen ? "수면 닫기" : "수면 열기") {
                Task {
                    if isOpen {
                        await dismissImmersiveSpace()
                    } else {
                        await openImmersiveSpace(id: "WaterSpace")
                    }
                    isOpen.toggle()
                }
            }
        }
        .padding()
    }
}
