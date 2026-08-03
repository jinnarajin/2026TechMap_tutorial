import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("WaterLight")
                .font(.largeTitle)

            Text("물속으로 들어간 뒤, 오른손 검지로 머리 위의 빛을 끌고 다니고\n엄지와 검지를 모아 빛을 강하게 만들어 보세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

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
        .padding(40)
    }
}
