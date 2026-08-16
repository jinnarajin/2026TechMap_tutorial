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

struct DraggableCloneComponent: Component {
}
