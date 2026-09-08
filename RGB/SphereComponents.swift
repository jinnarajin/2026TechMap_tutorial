//
//  SphereComponents.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit

struct OriginalSphereComponent: Component {
    let color: RGBColor
    let fixedPosition: SIMD3<Float>
}

struct SphereLightComponent: Component {
    var intensity: Float

    static let minimumIntensity: Float = 0.0
    static let maximumIntensity: Float = 2.4
    static let defaultIntensity: Float = 1.2
}
