import SwiftUI
import RealityKit

struct ImmersiveView: View {
    /// 머리 위 수면의 높이
    private let surfaceHeight: Float = 3.0

    var body: some View {
        RealityView { content in
            content.add(makeUnderwaterDome())
            content.add(makeWaterSurface())
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
        return water
    }
}
