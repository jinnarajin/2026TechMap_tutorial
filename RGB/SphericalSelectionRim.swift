//
//  SphericalSelectionRim.swift
//  RGB
//
//  Created by Minjae Son on 8/13/26.
//

import RealityKit
import UIKit

// MARK: - Selection Rim

/// Creates the white selection ring shown around the active sphere.
func createSphericalSelectionRim() -> ModelEntity {
    let mesh = makeSphericalRimMesh(
        outerRadius: 0.153,
        thickness: 0.002,
        segments: 96
    )

    let rim = ModelEntity(
        mesh: mesh,
        materials: [UnlitMaterial(color: .white)]
    )

    rim.name = "SelectionRim"
    rim.components.set(BillboardComponent())

    return rim
}

// MARK: - Spherical Rim Mesh

private func makeSphericalRimMesh(
    outerRadius: Float,
    thickness: Float,
    segments: Int
) -> MeshResource {
    let innerRadius = outerRadius - thickness

    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []

    for i in 0..<segments {
        let angle = Float(i) / Float(segments) * .pi * 2
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)

        positions.append(SIMD3(outerRadius * cosAngle, outerRadius * sinAngle, 0))
        positions.append(SIMD3(innerRadius * cosAngle, innerRadius * sinAngle, 0))

        normals.append(SIMD3(0, 0, 1))
        normals.append(SIMD3(0, 0, 1))
    }

    var indices: [UInt32] = []

    for i in 0..<segments {
        let next = (i + 1) % segments

        let outerCurrent = UInt32(i * 2)
        let innerCurrent = UInt32(i * 2 + 1)
        let outerNext = UInt32(next * 2)
        let innerNext = UInt32(next * 2 + 1)

        indices += [
            outerCurrent, outerNext, innerNext,
            outerCurrent, innerNext, innerCurrent
        ]
    }

    var descriptor = MeshDescriptor()
    descriptor.positions = MeshBuffers.Positions(positions)
    descriptor.normals = MeshBuffers.Normals(normals)
    descriptor.primitives = .triangles(indices)

    return try! MeshResource.generate(from: [descriptor])
}
