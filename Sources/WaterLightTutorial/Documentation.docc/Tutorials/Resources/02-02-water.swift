import SwiftUI
import RealityKit

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            content.add(makeWaterSurface())
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
        water.position = [0, 0.75, -1.5]
        return water
    }
}
