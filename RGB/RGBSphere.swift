//
//  RGBSphere.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit
import UIKit

// MARK: - RGB Color Component

/// Stores the RGB value associated with an entity.
struct RGBColorComponent: Component {
    var color: RGBColor
}

// MARK: - Material

func makeRGBMaterial(color: UIColor) -> PhysicallyBasedMaterial {
    var material = PhysicallyBasedMaterial()

    material.baseColor = .init(tint: color)

    // A high roughness keeps the sphere matte instead of
    // making it look like a reflective plastic balloon.
    material.metallic = 0.0
    material.roughness = 0.85

    // Slight transparency makes overlapping colors visible.
    material.blending = .transparent(
        opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.75)
    )

    // Emission makes the sphere appear luminous even in the
    // dark immersive environment.
    material.emissiveColor = .init(color: color)
    material.emissiveIntensity = 3.0

    return material
}

// MARK: - RGB Sphere

func makeRGBSphere(
    color: UIColor,
    rgbColor: RGBColor
) -> ModelEntity {

    let sphere = ModelEntity(
        mesh: .generateSphere(radius: 0.15),
        materials: [makeRGBMaterial(color: color)]
    )

    sphere.name = "RGBSphere"

    sphere.components.set(
        RGBColorComponent(color: rgbColor)
    )

    addRadiatingGlow(to: sphere, color: color)

    return sphere
}

// MARK: - Radiating Glow

/// Adds the billboarded radial glow used by both original and
/// dynamically created spheres.
func addRadiatingGlow(
    to sphere: ModelEntity,
    color: UIColor
) {
    guard let texture = makeRadialGlowTexture(color: color) else {
        return
    }

    let glow = makeGlowPlane(texture: texture, size: 0.50)

    glow.name = "RGBGlow"
    glow.position = SIMD3<Float>(0, 0, 0.015)
    glow.components.set(BillboardComponent())

    sphere.addChild(glow)
}

// MARK: - Glow Plane

private func makeGlowPlane(
    texture: TextureResource,
    size: Float
) -> ModelEntity {

    var material = UnlitMaterial(texture: texture)

    // The texture contains the radial alpha gradient.
    material.blending = .transparent(
        opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 1.0)
    )

    let plane = ModelEntity(
        mesh: .generatePlane(width: size, height: size),
        materials: [material]
    )

    plane.name = "RGBGlow"

    return plane
}

// MARK: - Radial Glow Texture

private func makeRadialGlowTexture(
    color: UIColor
) -> TextureResource? {

    let imageSize = 512

    let renderer = UIGraphicsImageRenderer(
        size: CGSize(
            width: imageSize,
            height: imageSize
        )
    )

    let image = renderer.image { context in
        let cgContext = context.cgContext

        let center = CGPoint(
            x: CGFloat(imageSize) / 2,
            y: CGFloat(imageSize) / 2
        )

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        color.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        )

        // The gradient creates a bright center that gradually
        // fades into a transparent edge.
        let colors = [
            CGColor(red: red, green: green, blue: blue, alpha: 0.75),
            CGColor(red: red, green: green, blue: blue, alpha: 0.35),
            CGColor(red: red, green: green, blue: blue, alpha: 0.10),
            CGColor(red: red, green: green, blue: blue, alpha: 0.0)
        ]

        let locations: [CGFloat] = [0.0, 0.25, 0.55, 1.0]

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: locations
        ) else {
            return
        }

        let radius = CGFloat(imageSize) / 2

        cgContext.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
    }

    guard let cgImage = image.cgImage else {
        return nil
    }

    // RealityKit may reuse textures with the same resource name,
    // so the RGB values are included in the name.
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 1

    color.getRed(
        &red,
        green: &green,
        blue: &blue,
        alpha: &alpha
    )

    let redValue = Int(red * 255)
    let greenValue = Int(green * 255)
    let blueValue = Int(blue * 255)

    let textureName = "RGBRadialGlow_\(redValue)_\(greenValue)_\(blueValue)"

    return try? TextureResource(
        image: cgImage,
        withName: textureName,
        options: .init(semantic: .color)
    )
}
