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
        } update: { content in
            guard let light = content.entities.first(where: {
                $0.name == "sunLight"
            }) else { return }

            if let hand = handTracking.indexTipPosition {
                // 손의 수평 이동을 3배로 증폭해 수면 위 태양을 끌고 다닌다.
                let target = SIMD3<Float>(hand.x * 3,
                                          surfaceHeight + 2,
                                          hand.z * 3)
                light.position = mix(light.position, target, t: 0.2)
                light.look(at: [0, 1.2, 0], from: light.position,
                           relativeTo: nil)
            }
        }
        .task {
            await handTracking.start()
        }
    }

    // makeUnderwaterDome(), makeWaterSurface(), makeSunLight()는 챕터 2와 동일
}
