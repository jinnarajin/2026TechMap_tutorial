import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("WaterLight")
                .font(.largeTitle)

            Button(isOpen ? "물 밖으로 나가기" : "물속으로 들어가기") {
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
