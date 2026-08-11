//
//  SphereInteraction.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit

func configureSphereForInteraction(
    _ sphere: ModelEntity
) {

    // =========================================================
    // Input
    // =========================================================

    sphere.components.set(
        InputTargetComponent()
    )

    // =========================================================
    // Collision
    //
    // This is only for the REAL visible sphere.
    //
    // There is no invisible overlap target anymore.
    // =========================================================

    sphere.components.set(
        CollisionComponent(
            shapes: [
                .generateSphere(
                    radius:
                        0.15
                )
            ]
        )
    )

    // =========================================================
    // Manipulation
    // =========================================================

    var manipulation =
        ManipulationComponent()

    manipulation.releaseBehavior =
        .stay

    sphere.components.set(
        manipulation
    )
}
