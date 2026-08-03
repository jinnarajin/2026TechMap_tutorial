import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    private let surfaceHeight: Float = 3.0

    var body: some View {
        RealityView { content in
            content.add(makeUnderwaterDome())

            let water = makeWaterSurface()
            water.components.set(ShimmerComponent())
            content.add(water)

            content.add(makeSunLight())
        }
        .task {
            await handTracking.start()
        }
    }

    // makeUnderwaterDome(), makeWaterSurface(), makeSunLight()는 챕터 2와 동일
}
