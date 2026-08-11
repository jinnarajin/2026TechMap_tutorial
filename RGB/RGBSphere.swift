//
//  RGBSphere.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit
import UIKit

struct RGBColorComponent:
    Component {

    var color:
        RGBColor
}

// MARK: - Material

func makeRGBMaterial(
    color: UIColor
) -> PhysicallyBasedMaterial {

    var material =
        PhysicallyBasedMaterial()

    material.baseColor =
        .init(
            tint:
                color
        )

    material.metallic =
        0.0

    material.roughness =
        0.1

    material.blending =
        .transparent(
            opacity:
                0.55
        )

    material.emissiveColor =
        .init(
            color:
                color
        )

    material.emissiveIntensity =
        2.0

    return material
}

// MARK: - RGB Sphere

func makeRGBSphere(
    color: UIColor,
    rgbColor: RGBColor
) -> ModelEntity {

    let sphere =
        ModelEntity(
            mesh:
                .generateSphere(
                    radius:
                        0.15
                ),
            materials: [
                makeRGBMaterial(
                    color:
                        color
                )
            ]
        )

    sphere.components.set(
        RGBColorComponent(
            color:
                rgbColor
        )
    )

    return sphere
}
