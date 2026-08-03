import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    private let waterCenter: SIMD3<Float> = [0, 0.75, -1.5]

    var body: some View {
        RealityView { content in
            let water = makeWaterSurface()
            water.name = "water"
            content.add(water)
            content.add(makeLight())
        } update: { content in
            guard let light = content.entities.first(where: {
                $0.name == "sunLight"
            }) else { return }

            if let hand = handTracking.indexTipPosition {
                let target = hand + SIMD3<Float>(0, 1.0, 0)
                light.position = mix(light.position, target, t: 0.2)
                light.look(at: waterCenter, from: light.position,
                           relativeTo: nil)
            }

            let pinch = handTracking.pinchAmount

            // 핀치를 쥘수록 빛이 강해진다 (8,000 ~ 25,000 lm)
            if var spot = light.components[SpotLightComponent.self] {
                spot.intensity = 8000 + 17000 * pinch
                light.components.set(spot)
            }

            // 핀치를 쥘수록 물결이 잔잔해져 반사가 또렷해진다
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

    // makeWaterSurface(), makeLight()는 챕터 2와 동일
}
