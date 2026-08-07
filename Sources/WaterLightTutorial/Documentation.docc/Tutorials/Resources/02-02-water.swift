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
    /// 돔보다 크게(60m) 만들어 가장자리를 돔 밖으로 숨기고,
    /// 방사형 투명도 페이드로 멀어질수록 어두운 물색에 녹아들게 한다.
    private func makeWaterSurface() -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(
            red: 0.05, green: 0.35, blue: 0.45, alpha: 1))
        material.metallic = 1.0
        material.roughness = 0.05

        if let fade = try? makeRadialFadeTexture() {
            material.blending = .transparent(
                opacity: .init(scale: 0.65, texture: .init(fade)))
        } else {
            material.blending = .transparent(opacity: 0.65)
        }

        let water = ModelEntity(
            mesh: .generatePlane(width: 60, depth: 60),
            materials: [material]
        )
        water.position = [0, surfaceHeight, 0]
        // 앞면(+Y)이 아래를 향하도록 X축 기준 180° 회전
        water.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        return water
    }

    /// 중심은 불투명하고 가장자리로 갈수록 투명해지는 방사형 그라데이션.
    /// 수면이 멀리서 심해 돔 색으로 자연스럽게 사라지게 한다.
    private func makeRadialFadeTexture() throws -> TextureResource {
        let size = 256
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let colors = [UIColor.white.cgColor,
                          UIColor.white.cgColor,
                          UIColor.black.cgColor]
            let gradient = CGGradient(colorsSpace: nil,
                                      colors: colors as CFArray,
                                      locations: [0, 0.35, 1])!
            let center = CGPoint(x: size / 2, y: size / 2)
            ctx.cgContext.drawRadialGradient(
                gradient, startCenter: center, startRadius: 0,
                endCenter: center, endRadius: CGFloat(size) / 2,
                options: [])
        }
        return try TextureResource(
            image: image.cgImage!,
            options: .init(semantic: .scalar))
    }
}
