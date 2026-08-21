//
//  RGBSphere.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit
import UIKit

// MARK: - RGB Color Component

struct RGBColorComponent: Component {
    var color: RGBColor
}

// MARK: - Material

/// Creates the luminous material used by an RGB sphere.
func makeRGBMaterial(color: UIColor) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()
    material.baseColor = .init(tint: color)
    material.metallic = 0.0
    material.roughness = 0.85
    material.blending = .transparent(opacity: .init(floatLiteral: 0.75))
    material.emissiveColor = .init(color: color)
    material.emissiveIntensity = 3
    return material
}

func applySphereLightIntensity(
    _ intensity: Float,
    to sphere: ModelEntity
) {
    let clampedIntensity = min(
        max(intensity, SphereLightComponent.minimumIntensity),
        SphereLightComponent.maximumIntensity
    )

    sphere.components.set(
        SphereLightComponent(intensity: clampedIntensity)
    )

    let color = sphere.components[RGBColorComponent.self]?.color.uiColor
        ?? .white
    let emissiveIntensity = 1.0 + (clampedIntensity * 5.0)

    if var material = sphere.model?.materials.first
        as? PhysicallyBasedMaterial {
        material.emissiveColor = .init(color: color)
        material.emissiveIntensity = emissiveIntensity
        sphere.model?.materials = [material]
    }

    guard let glow = sphere.children.first(where: { $0.name == "RGBGlow" })
        as? ModelEntity else {
        return
    }

    glow.scale = SIMD3<Float>(repeating: 0.9 + (clampedIntensity * 0.12))
}

// MARK: - RGB Sphere

func makeRGBSphere(color: UIColor, rgbColor: RGBColor) -> ModelEntity {
    let sphere = ModelEntity(
        mesh: .generateSphere(radius: 0.15),
        materials: [makeRGBMaterial(color: color)]
    )

    sphere.name = "RGBSphere"
    sphere.components.set(RGBColorComponent(color: rgbColor))
    addRadiatingGlow(to: sphere, color: color)
    applySphereLightIntensity(
        SphereLightComponent.defaultIntensity,
        to: sphere
    )

    return sphere
}

// MARK: - Radiating Glow

/// Uses a billboarded plane instead of a transparent sphere to avoid a balloon-like appearance.
func addRadiatingGlow(to sphere: ModelEntity, color: UIColor) {
    guard let texture = makeRadialGlowTexture(color: color) else { return }

    let glow = makeGlowPlane(texture: texture, size: 0.42)

    glow.position = SIMD3(0, 0, 0.015)
    glow.components.set(BillboardComponent())

    sphere.addChild(glow)
}

private func makeGlowPlane(texture: TextureResource, size: Float) -> ModelEntity {
    var material = UnlitMaterial(texture: texture)
    material.blending = .transparent(opacity: .init(floatLiteral: 1))

    let plane = ModelEntity(
        mesh: .generatePlane(width: size, height: size),
        materials: [material]
    )

    plane.name = "RGBGlow"
    return plane
}

// MARK: - Radial Glow Texture

private func makeRadialGlowTexture(color: UIColor) -> TextureResource? {
    let imageSize = 512

    let renderer = UIGraphicsImageRenderer(
        size: CGSize(width: imageSize, height: imageSize)
    )

    let image = renderer.image { context in
        let center = CGPoint(x: CGFloat(imageSize) / 2, y: CGFloat(imageSize) / 2)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let colors = [
            CGColor(red: red, green: green, blue: blue, alpha: 0.75),
            CGColor(red: red, green: green, blue: blue, alpha: 0.35),
            CGColor(red: red, green: green, blue: blue, alpha: 0.10),
            CGColor(red: red, green: green, blue: blue, alpha: 0)
        ]

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 0.25, 0.55, 1]
        ) else {
            return
        }

        let radius = CGFloat(imageSize) / 2

        context.cgContext.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
    }

    guard let cgImage = image.cgImage else { return nil }

    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 1

    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    let textureName = "RGBRadialGlow_\(Int(red * 255))_\(Int(green * 255))_\(Int(blue * 255))"

    return try? TextureResource(
        image: cgImage,
        withName: textureName,
        options: .init(semantic: .color)
    )
}
