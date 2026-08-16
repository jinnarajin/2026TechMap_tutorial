//
//  SphereComponents.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit

/// Identifies one of the three permanent RGB spheres.
struct OriginalSphereComponent: Component {
    let color: RGBColor
    let fixedPosition: SIMD3<Float>
}
