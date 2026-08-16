//
//  SphereInteractionManager.swift
//  RGB
//
//  Created by Minjae Son on 8/11/26.
//

import SwiftUI
import RealityKit
import Combine
import UIKit

@MainActor
final class SphereInteractionManager: ObservableObject {

    // MARK: - Interaction State

    private enum InteractionState {
        case idle
        case original(
            sphere: ModelEntity,
            position: SIMD3<Float>,
            clone: ModelEntity
        )
        case movable(sphere: ModelEntity)
        case overlap(
            target: ModelEntity,
            mixedSphere: ModelEntity
        )
    }

    private var state: InteractionState = .idle

    // MARK: - Event Subscriptions

    private var manipulationSubscription: EventSubscription?
    private var transformSubscription: EventSubscription?
    private var releaseSubscription: EventSubscription?

    // MARK: - Scene Objects

    private var movableSpheres: [ModelEntity] = []
    private var overlapTargets: [ModelEntity] = []

    private weak var selectedSphere: ModelEntity?
    private var selectionRim: ModelEntity?

    private let overlapSystem = SphereOverlapSystem()
    private let sphereRadius: Float = 0.15
    private let overlapHitRadius: Float = 0.155

    // MARK: - Setup

    func subscribe(to content: RealityViewContent) {
        manipulationSubscription = content.subscribe(
            to: ManipulationEvents.WillBegin.self
        ) { [weak self] event in
            self?.handleManipulationBegan(event)
        }

        transformSubscription = content.subscribe(
            to: ManipulationEvents.DidUpdateTransform.self
        ) { [weak self] event in
            self?.handleManipulationUpdated(event)
        }

        releaseSubscription = content.subscribe(
            to: ManipulationEvents.WillRelease.self
        ) { [weak self] event in
            self?.handleManipulationReleased(event)
        }
    }

    // MARK: - Selection

    private func selectSphere(_ sphere: ModelEntity) {
        guard selectedSphere !== sphere else {
            return
        }

        removeSelectionRim()

        selectedSphere = sphere

        let rim = createSphericalSelectionRim()
        sphere.addChild(rim)
        selectionRim = rim
    }

    private func removeSelectionRim() {
        selectionRim?.removeFromParent()
        selectionRim = nil
        selectedSphere = nil
    }

    // MARK: - Manipulation

    private func handleManipulationBegan(
        _ event: ManipulationEvents.WillBegin
    ) {
        guard let entity = event.entity as? ModelEntity,
              case .idle = state else {
            return
        }

        // An overlap target creates a new mixed sphere.
        if let component = entity.components[OverlapVisualComponent.self] {
            guard let overlap = overlapSystem
                .checkOverlap(spheres: movableSpheres)
                .first(where: { $0.key == component.overlapKey }) else {
                return
            }

            let mixedSphere = createMixedSphere(overlap: overlap)

            state = .overlap(
                target: entity,
                mixedSphere: mixedSphere
            )

            selectSphere(mixedSphere)
            return
        }

        // An original RGB sphere creates a movable clone.
        if let original = entity.components[OriginalSphereComponent.self] {
            let clone = createClone(from: entity)

            clone.position = entity.position
            entity.parent?.addChild(clone)
            movableSpheres.append(clone)

            state = .original(
                sphere: entity,
                position: original.fixedPosition,
                clone: clone
            )

            selectSphere(clone)
            return
        }

        // Existing clones and mixed spheres can be moved directly.
        guard movableSpheres.contains(where: { $0 === entity }) else {
            return
        }

        state = .movable(sphere: entity)
        selectSphere(entity)
    }

    private func handleManipulationUpdated(
        _ event: ManipulationEvents.DidUpdateTransform
    ) {
        guard let entity = event.entity as? ModelEntity else {
            return
        }

        switch state {
        case let .original(sphere, position, clone):
            guard entity === sphere else {
                return
            }

            // Keep the original RGB sphere fixed while the clone follows the gesture.
            sphere.position = position
            clone.position = sphere.position

        case .movable:
            // RealityKit handles movement automatically.
            return

        case let .overlap(target, mixedSphere):
            guard entity === target else {
                return
            }

            moveMixedSphere(mixedSphere, to: target)

        case .idle:
            return
        }
    }

    private func handleManipulationReleased(
        _ event: ManipulationEvents.WillRelease
    ) {
        guard let entity = event.entity as? ModelEntity else {
            return
        }

        switch state {
        case let .original(sphere, position, clone):
            guard entity === sphere else {
                return
            }

            sphere.position = position
            clone.isEnabled = true

            state = .idle
            updateOverlapTargets()

        case let .movable(sphere):
            guard entity === sphere else {
                return
            }

            state = .idle
            updateOverlapTargets()

        case let .overlap(target, mixedSphere):
            guard entity === target else {
                return
            }

            moveMixedSphere(mixedSphere, to: target)

            mixedSphere.isEnabled = true
            target.removeFromParent()

            overlapTargets.removeAll {
                $0 === target
            }

            state = .idle
            updateOverlapTargets()

        case .idle:
            return
        }
    }

    // MARK: - Cleanup

    func deleteAllMovableSpheres() {
        removeSelectionRim()

        movableSpheres.forEach {
            $0.removeFromParent()
        }

        overlapTargets.forEach {
            $0.removeFromParent()
        }

        movableSpheres.removeAll()
        overlapTargets.removeAll()

        state = .idle
    }

    // MARK: - Overlap Targets

    private func updateOverlapTargets() {
        guard case .idle = state else {
            return
        }

        let overlaps = overlapSystem.checkOverlap(
            spheres: movableSpheres
        )

        let currentKeys = Set(overlaps.map(\.key))

        // Remove targets whose spheres no longer overlap.
        overlapTargets.removeAll { target in
            guard let component =
                target.components[OverlapVisualComponent.self] else {
                target.removeFromParent()
                return true
            }

            guard currentKeys.contains(component.overlapKey) else {
                target.removeFromParent()
                return true
            }

            return false
        }

        for overlap in overlaps {

            // Update an existing target.
            if let target = overlapTargets.first(where: {
                $0.components[OverlapVisualComponent.self]?.overlapKey
                    == overlap.key
            }) {
                if let parent = target.parent {
                    target.position = parent.convert(
                        position: overlap.position,
                        from: nil
                    )
                }

                target.components.set(
                    OverlapVisualComponent(
                        overlapKey: overlap.key,
                        mixedColor: overlap.color
                    )
                )

                continue
            }

            // Create a new invisible interaction target.
            guard let parent = overlap.firstSphere.parent else {
                continue
            }

            let target = ModelEntity()

            target.name = "OverlapTarget_\(overlap.key)"
            target.position = parent.convert(
                position: overlap.position,
                from: nil
            )

            parent.addChild(target)

            target.components.set(
                CollisionComponent(
                    shapes: [
                        .generateSphere(radius: overlapHitRadius)
                    ]
                )
            )

            target.components.set(InputTargetComponent())

            target.components.set(
                OverlapVisualComponent(
                    overlapKey: overlap.key,
                    mixedColor: overlap.color
                )
            )

            var manipulation = ManipulationComponent()
            manipulation.releaseBehavior = .stay
            target.components.set(manipulation)

            overlapTargets.append(target)
        }
    }

    // MARK: - Sphere Creation

    private func createClone(
        from original: ModelEntity
    ) -> ModelEntity {
        let color = original.components[RGBColorComponent.self]?.color ?? .red

        let clone = ModelEntity(
            mesh: .generateSphere(radius: sphereRadius),
            materials: [
                makeRGBMaterial(color: color.uiColor)
            ]
        )

        clone.name = "Clone"

        clone.components.set(
            RGBColorComponent(color: color)
        )

        addRadiatingGlow(
            to: clone,
            color: color.uiColor
        )

        configureSphereForInteraction(clone)

        return clone
    }

    private func createMixedSphere(
        overlap: SphereOverlap
    ) -> ModelEntity {
        let mixedSphere = ModelEntity(
            mesh: .generateSphere(radius: sphereRadius),
            materials: [
                makeRGBMaterial(
                    color: overlap.color.uiColor
                )
            ]
        )

        mixedSphere.name = "MixedSphere"

        mixedSphere.components.set(
            RGBColorComponent(
                color: overlap.color
            )
        )

        addRadiatingGlow(
            to: mixedSphere,
            color: overlap.color.uiColor
        )

        configureSphereForInteraction(mixedSphere)

        if let parent = overlap.firstSphere.parent {
            mixedSphere.position = parent.convert(
                position: overlap.position,
                from: nil
            )

            parent.addChild(mixedSphere)
        }

        movableSpheres.append(mixedSphere)

        return mixedSphere
    }

    // MARK: - Helpers

    /// Keeps a mixed sphere aligned with the invisible overlap target.
    private func moveMixedSphere(
        _ sphere: ModelEntity,
        to target: ModelEntity
    ) {
        guard let parent = target.parent else {
            sphere.position = target.position
            return
        }

        sphere.position = parent.convert(
            position: target.position,
            from: target.parent
        )
    }
}
