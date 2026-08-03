import SwiftUI
import RealityKit

@main
struct WaterLightApp: App {
    init() {
        ShimmerComponent.registerComponent()
        ShimmerSystem.registerSystem()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "WaterSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
