import SwiftUI
import RealityKit

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            let water = makeWaterSurface()
            content.add(water)
            content.add(makeLight())
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
        water.position = [0, 0.75, -1.5]
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
        light.look(at: [0, 0.75, -1.5], from: light.position,
                   relativeTo: nil)
        return light
    }
}
