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

    // MARK: - Event Subscriptions

    private var manipulationSubscription: EventSubscription?
    private var transformSubscription: EventSubscription?
    private var releaseSubscription: EventSubscription?

    // MARK: - Active Interaction

    private var activeOriginal: ModelEntity?
    private var activeOriginalPosition: SIMD3<Float>?

    private var activeClone: ModelEntity?
    private var activeMovableSphere: ModelEntity?
    private var activeMixedSphere: ModelEntity?
    private var activeOverlapTarget: ModelEntity?
    private var activeOverlap: SphereOverlap?

    private var isDraggingOriginal = false
    private var isDraggingMovableSphere = false
    private var isDraggingOverlap = false

    // MARK: - Scene Objects

    /// Contains only real movable spheres:
    /// RGB clones and mixed-color spheres.
    private var movableSpheres: [ModelEntity] = []

    /// Invisible interaction points used to select color overlaps.
    private var overlapTargets: [ModelEntity] = []

    private weak var selectedSphere: ModelEntity?
    private var selectionRim: ModelEntity?

    private let overlapSystem = SphereOverlapSystem()

    private let sphereRadius: Float = 0.15
    private let overlapHitRadius: Float = 0.155

    // MARK: - Event Subscription

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

    // MARK: - Manipulation Began

    private func handleManipulationBegan(
        _ event: ManipulationEvents.WillBegin
    ) {
        guard let entity = event.entity as? ModelEntity else {
            return
        }

        if overlapTargets.contains(where: { $0 === entity }) {
            handleOverlapBegan(entity)
            return
        }

        if let original = entity.components[OriginalSphereComponent.self] {
            handleOriginalBegan(entity, original: original)
            return
        }

        guard movableSpheres.contains(where: { $0 === entity }) else {
            return
        }

        guard canBeginManipulation else {
            return
        }

        activeMovableSphere = entity
        isDraggingMovableSphere = true

        selectSphere(entity)
    }

    // MARK: - Original Sphere

    private func handleOriginalBegan(
        _ entity: ModelEntity,
        original: OriginalSphereComponent
    ) {
        guard canBeginManipulation else {
            return
        }

        activeOriginal = entity
        activeOriginalPosition = original.fixedPosition
        activeClone = nil
        isDraggingOriginal = true

        let clone = createClone(from: entity)
        clone.position = entity.position

        entity.parent?.addChild(clone)
        movableSpheres.append(clone)

        activeClone = clone
        selectSphere(clone)
    }

    // MARK: - Overlap

    private func handleOverlapBegan(_ entity: ModelEntity) {
        guard canBeginManipulation else {
            return
        }

        guard let component = entity.components[OverlapVisualComponent.self] else {
            return
        }

        guard let overlap = overlapSystem
            .checkOverlap(spheres: movableSpheres)
            .first(where: { $0.key == component.overlapKey })
        else {
            return
        }

        let mixedSphere = createMixedSphere(overlap: overlap)

        activeOverlapTarget = entity
        activeMixedSphere = mixedSphere
        activeOverlap = overlap
        isDraggingOverlap = true

        selectSphere(mixedSphere)
    }

    // MARK: - Manipulation Updated

    private func handleManipulationUpdated(
        _ event: ManipulationEvents.DidUpdateTransform
    ) {
        guard let entity = event.entity as? ModelEntity else {
            return
        }

        if isDraggingOriginal {
            updateOriginal(event: event, entity: entity)
            return
        }

        if isDraggingMovableSphere {
            return
        }

        if isDraggingOverlap {
            updateOverlap(event: event, entity: entity)
        }
    }

    private func updateOriginal(
        event: ManipulationEvents.DidUpdateTransform,
        entity: ModelEntity
    ) {
        guard
            let original = activeOriginal,
            let fixedPosition = activeOriginalPosition,
            event.entity === original
        else {
            return
        }

        original.position = fixedPosition
        activeClone?.position = original.position
    }

    private func updateOverlap(
        event: ManipulationEvents.DidUpdateTransform,
        entity: ModelEntity
    ) {
        guard
            let target = activeOverlapTarget,
            let mixedSphere = activeMixedSphere,
            event.entity === target
        else {
            return
        }

        guard let parent = target.parent else {
            mixedSphere.position = target.position
            return
        }

        mixedSphere.position = parent.convert(
            position: target.position,
            from: target.parent
        )
    }

    // MARK: - Manipulation Released

    private func handleManipulationReleased(
        _ event: ManipulationEvents.WillRelease
    ) {
        guard let entity = event.entity as? ModelEntity else {
            return
        }

        if isDraggingOriginal {
            releaseOriginal(event: event, entity: entity)
            return
        }

        if isDraggingMovableSphere {
            releaseMovableSphere(event: event, entity: entity)
            return
        }

        if isDraggingOverlap {
            releaseOverlap(event: event, entity: entity)
        }
    }

    private func releaseOriginal(
        event: ManipulationEvents.WillRelease,
        entity: ModelEntity
    ) {
        guard
            let original = activeOriginal,
            event.entity === original
        else {
            return
        }

        if let fixedPosition = activeOriginalPosition {
            original.position = fixedPosition
        }

        activeClone?.isEnabled = true

        activeOriginal = nil
        activeOriginalPosition = nil
        activeClone = nil
        isDraggingOriginal = false

        updateOverlapTargets()
    }

    private func releaseMovableSphere(
        event: ManipulationEvents.WillRelease,
        entity: ModelEntity
    ) {
        guard
            let sphere = activeMovableSphere,
            event.entity === sphere
        else {
            return
        }

        activeMovableSphere = nil
        isDraggingMovableSphere = false

        updateOverlapTargets()
    }

    private func releaseOverlap(
        event: ManipulationEvents.WillRelease,
        entity: ModelEntity
    ) {
        guard
            let target = activeOverlapTarget,
            event.entity === target
        else {
            return
        }

        if let mixedSphere = activeMixedSphere {
            if let parent = target.parent {
                mixedSphere.position = parent.convert(
                    position: target.position,
                    from: target.parent
                )
            } else {
                mixedSphere.position = target.position
            }

            mixedSphere.isEnabled = true
        }

        target.removeFromParent()

        overlapTargets.removeAll { $0 === target }

        activeOverlapTarget = nil
        activeMixedSphere = nil
        activeOverlap = nil
        isDraggingOverlap = false

        updateOverlapTargets()
    }

    // MARK: - Clear

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

        activeClone = nil
        activeMovableSphere = nil
        activeMixedSphere = nil
        activeOverlapTarget = nil
        activeOverlap = nil

        isDraggingMovableSphere = false
        isDraggingOverlap = false
    }

    // MARK: - Overlap Targets

    private func updateOverlapTargets() {
        guard !isDraggingOriginal, !isDraggingOverlap else {
            return
        }

        let overlaps = overlapSystem.checkOverlap(
            spheres: movableSpheres
        )

        let currentKeys = Set(
            overlaps.map(\.key)
        )

        removeObsoleteOverlapTargets(
            currentKeys: currentKeys
        )

        for overlap in overlaps {
            updateOrCreateOverlapTarget(
                for: overlap
            )
        }
    }

    private func removeObsoleteOverlapTargets(
        currentKeys: Set<String>
    ) {
        overlapTargets.removeAll { target in
            guard let component = target.components[
                OverlapVisualComponent.self
            ] else {
                target.removeFromParent()
                return true
            }

            guard currentKeys.contains(component.overlapKey) else {
                target.removeFromParent()
                return true
            }

            return false
        }
    }

    private func updateOrCreateOverlapTarget(
        for overlap: SphereOverlap
    ) {
        if let target = overlapTargets.first(where: {
            $0.components[OverlapVisualComponent.self]?.overlapKey == overlap.key
        }) {
            updateOverlapTarget(target, with: overlap)
            return
        }

        createOverlapTarget(for: overlap)
    }

    private func updateOverlapTarget(
        _ target: ModelEntity,
        with overlap: SphereOverlap
    ) {
        if let parent = target.parent {
            target.position = parent.convert(
                position: overlap.position,
                from: nil
            )
        } else {
            target.position = overlap.position
        }

        target.components.set(
            OverlapVisualComponent(
                overlapKey: overlap.key,
                mixedColor: overlap.color
            )
        )
    }

    private func createOverlapTarget(
        for overlap: SphereOverlap
    ) {
        guard let parent = overlap.firstSphere.parent else {
            return
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
                shapes: [.generateSphere(radius: overlapHitRadius)]
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

    // MARK: - Sphere Creation

    private func createClone(
        from original: ModelEntity
    ) -> ModelEntity {

        let color = original.components[
            RGBColorComponent.self
        ]?.color ?? .red

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
            RGBColorComponent(color: overlap.color)
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

    private var canBeginManipulation: Bool {
        !isDraggingOriginal &&
        !isDraggingMovableSphere &&
        !isDraggingOverlap
    }
}
