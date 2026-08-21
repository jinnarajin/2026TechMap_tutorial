//
//  SphereInteraction.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import RealityKit

func configureSphereForInteraction(_ sphere: ModelEntity) {
    sphere.components.set(InputTargetComponent())

    sphere.components.set(
        CollisionComponent(shapes: [.generateSphere(radius: 0.15)])
    )

    var manipulation = ManipulationComponent()
    manipulation.releaseBehavior = .stay
    sphere.components.set(manipulation)
}
