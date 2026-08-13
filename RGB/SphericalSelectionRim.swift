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
// SphereInteractionManager only needs to call:
//
//     createSphericalSelectionRim()
//
// All visual configuration stays here:
// - size
// - thickness
// - segments
// - gradient
// - material
// - billboard
// - mesh
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
    // Unlit keeps the rim visually clean.
    //
    // The actual gradient is stored in the mesh's vertex colors.
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
    // The ring always faces the user.
    //
    // This makes the flat ring behave visually more like
    // a spherical outline rather than a 3D donut.
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
// Creates a thin flat annulus.
//
// This is intentionally NOT a torus.
//
// The rim gets a subtle directional gradient:
//
//     brighter
//          ↓
//
//     white ────────
//       ╲
//        ╲
//         ╲
//          ─────────
//              ↓
//           softer
//
// Similar visually to:
//
// LinearGradient(
//     colors: [
//         .white.opacity(0.6),
//         .white.opacity(0.1)
//     ],
//     startPoint: .topLeading,
//     endPoint: .bottomTrailing
// )
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

    var colors:
        [SIMD4<Float>] = []


    // =========================================================
    // MARK: Gradient colors
    // =========================================================
    //
    // Stronger white:
    //
    //     0.85
    //
    // Softer white:
    //
    //     0.18
    //
    // The alpha values are deliberately not too low because
    // this is a selection indicator.
    //
    // =========================================================

    let brightColor =
        SIMD4<Float>(
            1.0,
            1.0,
            1.0,
            0.85
        )

    let softColor =
        SIMD4<Float>(
            1.0,
            1.0,
            1.0,
            0.18
        )


    // =========================================================
    // MARK: Generate vertices
    // =========================================================

    for i in
        0..<segments {

        let normalized =
            Float(i)
            /
            Float(segments)


        let angle =
            normalized
            *
            Float.pi
            *
            2.0


        let cosAngle =
            cos(angle)

        let sinAngle =
            sin(angle)


        // =====================================================
        // Gradient position
        // =====================================================
        //
        // Convert the circular position into a directional
        // gradient.
        //
        // The diagonal direction is approximately equivalent
        // to SwiftUI:
        //
        // startPoint: .topLeading
        // endPoint: .bottomTrailing
        //
        // =====================================================

        let gradientX =
            (cosAngle + 1.0)
            * 0.5

        let gradientY =
            (sinAngle + 1.0)
            * 0.5


        let gradientPosition =
            (gradientX + gradientY)
            * 0.5


        // -----------------------------------------------------
        // Invert so one side is brighter.
        // -----------------------------------------------------

        let brightness =
            1.0
            -
            gradientPosition


        // -----------------------------------------------------
        // Interpolate alpha.
        // -----------------------------------------------------

        let alpha =
            0.18
            +
            (
                0.85
                -
                0.18
            )
            *
            brightness


        let vertexColor =
            SIMD4<Float>(
                1.0,
                1.0,
                1.0,
                alpha
            )


        // =====================================================
        // Outer vertex
        // =====================================================

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

        colors.append(
            vertexColor
        )


        // =====================================================
        // Inner vertex
        // =====================================================

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

        colors.append(
            vertexColor
        )
    }


    // =========================================================
    // MARK: Generate triangles
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
    // MARK: Mesh descriptor
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


    descriptor.colors =
        MeshBuffers.Colors(
            colors
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
