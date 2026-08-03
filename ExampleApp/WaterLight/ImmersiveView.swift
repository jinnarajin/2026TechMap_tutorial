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
                // 손 위치보다 1m 위에서 비추되, 부드럽게 따라가기
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

    private func makeWaterSurface() -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(
            red: 0.05, green: 0.25, blue: 0.3, alpha: 1))
        material.metallic = 1.0
        material.roughness = 0.05
        material.clearcoat = .init(floatLiteral: 1.0)

        let water = ModelEntity(
            mesh: .generatePlane(width: 2, depth: 2, cornerRadius: 1),
            materials: [material]
        )
        // 바닥에서 75cm 높이, 사용자 앞 1.5m
        water.position = waterCenter
        water.components.set(ShimmerComponent())
        return water
    }

    private func makeLight() -> Entity {
        let light = Entity()
        light.name = "sunLight"
        var spot = SpotLightComponent()
        spot.intensity = 8000
        spot.color = .init(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
        spot.attenuationRadius = 6
        light.components.set(spot)

        light.position = [0, 2.2, -1.5]
        light.look(at: waterCenter, from: light.position, relativeTo: nil)
        return light
    }
}
