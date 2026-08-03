import SwiftUI
import RealityKit

struct ImmersiveView: View {
    /// 머리 위 수면의 높이
    private let surfaceHeight: Float = 3.0

    var body: some View {
        RealityView { content in
            content.add(makeUnderwaterDome())

            let water = makeWaterSurface()
            water.components.set(ShimmerComponent())
            content.add(water)

            content.add(makeSunLight())
        }
    }

    private func makeUnderwaterDome() -> ModelEntity {
        var material = UnlitMaterial(color: UIColor(
            red: 0.01, green: 0.08, blue: 0.12, alpha: 1))
        material.faceCulling = .front

        return ModelEntity(mesh: .generateSphere(radius: 30),
                           materials: [material])
    }

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
        water.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
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
