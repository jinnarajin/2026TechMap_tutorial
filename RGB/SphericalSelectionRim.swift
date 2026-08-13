//
//  SphericalSelectionRim.swift
//  RGB
//
//  Created by Minjae Son on 8/13/26.
//

import RealityKit
import UIKit


// =============================================================
// MARK: - Selection Rim
// =============================================================
//
// This file is responsible ONLY for the visual selection rim.
//
// SphereInteractionManager does not need to know:
//
// - how the mesh is generated
// - how thick the rim is
// - how large the rim is
// - what material it uses
//
// It simply calls:
//
//     createSphericalSelectionRim()
//
// =============================================================


func createSphericalSelectionRim() -> ModelEntity {

    // =========================================================
    // MARK: Configuration
    // =========================================================

    let outerRadius:
        Float = 0.153

    let thickness:
        Float = 0.002

    let segments:
        Int = 96


    // =========================================================
    // MARK: Mesh
    // =========================================================

    let mesh =
        makeSphericalRimMesh(
            outerRadius:
                outerRadius,

            thickness:
                thickness,

            segments:
                segments
        )


    // =========================================================
    // MARK: Material
    // =========================================================
    //
    // Unlit keeps the rim:
    //
    // - pure white
    // - unaffected by scene lighting
    // - without shadows
    // - without metallic reflections
    //
    // =========================================================

    let material =
        UnlitMaterial(
            color:
                UIColor.white
        )


    // =========================================================
    // MARK: Entity
    // =========================================================

    let rim =
        ModelEntity(
            mesh:
                mesh,

            materials:
                [
                    material
                ]
        )


    rim.name =
        "SelectionRim"


    // =========================================================
    // MARK: Billboard
    // =========================================================
    //
    // Keeps the flat circular rim facing the user.
    //
    // This is important because the sphere itself is
    // transparent.
    //
    // =========================================================

    rim.components.set(
        BillboardComponent()
    )


    // =========================================================
    // MARK: Visual only
    // =========================================================

    rim.components.remove(
        CollisionComponent.self
    )

    rim.components.remove(
        InputTargetComponent.self
    )

    rim.components.remove(
        ManipulationComponent.self
    )


    return rim
}


// =============================================================
// MARK: - Spherical Rim Mesh
// =============================================================
//
// Creates a very thin flat circular annulus.
//
// This is NOT a torus.
//
// A torus is a 3D donut and can show its back side through
// transparent spheres.
//
// This mesh is a flat ring that is always facing the user.
//
// =============================================================

private func makeSphericalRimMesh(
    outerRadius:
        Float,

    thickness:
        Float,

    segments:
        Int
) -> MeshResource {

    let innerRadius =
        outerRadius
        -
        thickness


    var positions:
        [SIMD3<Float>] = []

    var normals:
        [SIMD3<Float>] = []


    // =========================================================
    // Generate vertices
    // =========================================================

    for i in
        0..<segments {

        let angle =
            Float(i)
            /
            Float(segments)
            *
            Float.pi
            *
            2.0


        let cosAngle =
            cos(angle)

        let sinAngle =
            sin(angle)


        // -----------------------------------------------------
        // Outer vertex
        // -----------------------------------------------------

        positions.append(
            SIMD3<Float>(
                outerRadius * cosAngle,
                outerRadius * sinAngle,
                0
            )
        )

        normals.append(
            SIMD3<Float>(
                0,
                0,
                1
            )
        )


        // -----------------------------------------------------
        // Inner vertex
        // -----------------------------------------------------

        positions.append(
            SIMD3<Float>(
                innerRadius * cosAngle,
                innerRadius * sinAngle,
                0
            )
        )

        normals.append(
            SIMD3<Float>(
                0,
                0,
                1
            )
        )
    }


    // =========================================================
    // Generate triangles
    // =========================================================

    var indices:
        [UInt32] = []


    for i in
        0..<segments {

        let next =
            (i + 1)
            %
            segments


        let outerCurrent =
            UInt32(
                i * 2
            )

        let innerCurrent =
            UInt32(
                i * 2 + 1
            )

        let outerNext =
            UInt32(
                next * 2
            )

        let innerNext =
            UInt32(
                next * 2 + 1
            )


        // -----------------------------------------------------
        // Triangle 1
        // -----------------------------------------------------

        indices.append(
            outerCurrent
        )

        indices.append(
            outerNext
        )

        indices.append(
            innerNext
        )


        // -----------------------------------------------------
        // Triangle 2
        // -----------------------------------------------------

        indices.append(
            outerCurrent
        )

        indices.append(
            innerNext
        )

        indices.append(
            innerCurrent
        )
    }


    // =========================================================
    // Mesh descriptor
    // =========================================================

    var descriptor =
        MeshDescriptor()


    descriptor.positions =
        MeshBuffers.Positions(
            positions
        )


    descriptor.normals =
        MeshBuffers.Normals(
            normals
        )


    descriptor.primitives =
        .triangles(
            indices
        )


    return try! MeshResource.generate(
        from:
            [
                descriptor
            ]
    )
}
