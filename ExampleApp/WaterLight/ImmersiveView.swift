import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    /// 머리 위 수면의 높이
    private let surfaceHeight: Float = 3.0

    var body: some View {
        RealityView { content in
            content.add(makeUnderwaterDome())

            let water = makeWaterSurface()
            water.name = "water"
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

    /// 사용자를 감싸는 짙은 심해 돔. 안쪽 면이 보이도록 뒤집는다.
    private func makeUnderwaterDome() -> ModelEntity {
        var material = UnlitMaterial(color: UIColor(
            red: 0.01, green: 0.08, blue: 0.12, alpha: 1))
        material.faceCulling = .front

        return ModelEntity(mesh: .generateSphere(radius: 30),
                           materials: [material])
    }

    /// 머리 위 수면. 아래에서 올려다보므로 앞면이 아래를 향하게 뒤집는다.
    private func makeWaterSurface() -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(
            red: 0.05, green: 0.35, blue: 0.45, alpha: 1))
        material.metallic = 1.0
        material.roughness = 0.05
        material.blending = .transparent(opacity: 0.65)

        let water = ModelEntity(
            mesh: .generatePlane(width: 30, depth: 30),
            materials: [material]
        )
        water.position = [0, surfaceHeight, 0]
        // 앞면(+Y)이 아래를 향하도록 X축 기준 180° 회전
        water.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        water.components.set(ShimmerComponent())
        return water
    }

    /// 수면 위의 태양. 물을 뚫고 들어오는 빛 기둥 역할.
    private func makeSunLight() -> Entity {
        let light = Entity()
        light.name = "sunLight"
        var spot = SpotLightComponent()
        spot.intensity = 10000
        spot.color = .init(red: 0.85, green: 0.95, blue: 1.0, alpha: 1)
        spot.attenuationRadius = 15
        spot.innerAngleInDegrees = 25
        spot.outerAngleInDegrees = 60
        light.components.set(spot)

        light.position = [0, surfaceHeight + 2, 0]
        light.look(at: [0, 1.2, 0], from: light.position, relativeTo: nil)
        return light
    }
}
