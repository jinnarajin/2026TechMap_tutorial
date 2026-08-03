import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    var body: some View {
        RealityView { content in
            let water = makeWaterSurface()
            content.add(water)
            content.add(makeLight())
        }
        .task {
            await handTracking.start()
        }
    }

    // makeWaterSurface(), makeLight()는 챕터 2와 동일
}
