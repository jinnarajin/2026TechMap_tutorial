import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    private let surfaceHeight: Float = 3.0

    var body: some View {
        RealityView { content in
            content.add(makeUnderwaterDome())

            let water = makeWaterSurface()
            water.name = "water"
            water.components.set(ShimmerComponent())
            content.add(water)

            content.add(makeSunLight())
        } update: { content in
            guard let light = content.entities.first(where: {
                $0.name == "sunLight"
            }) else { return }

            if let hand = handTracking.indexTipPosition {
                let target = SIMD3<Float>(hand.x * 3,
                                          surfaceHeight + 2,
                                          hand.z * 3)
                light.position = mix(light.position, target, t: 0.2)
                light.look(at: [0, 1.2, 0], from: light.position,
                           relativeTo: nil)
            }

            let pinch = handTracking.pinchAmount

            // 핀치를 쥘수록 빛이 강해진다 (10,000 ~ 40,000 lm)
            if var spot = light.components[SpotLightComponent.self] {
                spot.intensity = 10000 + 30000 * pinch
                light.components.set(spot)
            }

            // 핀치를 쥘수록 물결이 잔잔해져 빛이 또렷하게 들어온다
            if let water = content.entities.first(where: {
                $0.name == "water"
            }), var shimmer = water.components[ShimmerComponent.self] {
                shimmer.strength = 1 - pinch
                water.components.set(shimmer)
            }
        }
        .task {
            await handTracking.start()
        }
    }

    // makeUnderwaterDome(), makeWaterSurface(), makeSunLight()는 챕터 2와 동일
}
