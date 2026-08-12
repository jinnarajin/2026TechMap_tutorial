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

    // =========================================================
    // MARK: - Event subscriptions
    // =========================================================

    private var manipulationSubscription:
        EventSubscription?

    private var transformSubscription:
        EventSubscription?

    private var releaseSubscription:
        EventSubscription?


    // =========================================================
    // MARK: - Permanent original
    // =========================================================

    private var activeOriginal:
        ModelEntity?

    private var activeOriginalPosition:
        SIMD3<Float>?


    // =========================================================
    // MARK: - Newly created clone
    // =========================================================

    private var activeClone:
        ModelEntity?


    // =========================================================
    // MARK: - Existing movable sphere
    //
    // Includes:
    //
    // - RGB clones
    // - mixed spheres
    // =========================================================

    private var activeMovableSphere:
        ModelEntity?


    // =========================================================
    // MARK: - Mixed sphere
    // =========================================================

    private var activeMixedSphere:
        ModelEntity?


    // =========================================================
    // MARK: - Invisible overlap target
    // =========================================================

    private var activeOverlapTarget:
        ModelEntity?


    // =========================================================
    // MARK: - Active overlap
    // =========================================================

    private var activeOverlap:
        SphereOverlap?


    // =========================================================
    // MARK: - Interaction state
    // =========================================================

    private var isDraggingOriginal =
        false

    private var isDraggingMovableSphere =
        false

    private var isDraggingOverlap =
        false


    // =========================================================
    // MARK: - All REAL movable spheres
    //
    // Contains:
    //
    // - RGB clones
    // - mixed spheres
    //
    // Does NOT contain:
    //
    // - permanent RGB originals
    // - invisible overlap targets
    // =========================================================

    private var movableSpheres:
        [ModelEntity] = []


    // =========================================================
    // MARK: - Invisible overlap targets
    // =========================================================

    private var overlapTargets:
        [ModelEntity] = []


    // =========================================================
    // MARK: - Overlap system
    // =========================================================

    private let overlapSystem =
        SphereOverlapSystem()


    // =========================================================
    // MARK: - Configuration
    // =========================================================

    private let sphereRadius:
        Float = 0.15

    private let overlapHitRadius:
        Float = 0.155


    // =========================================================
    // MARK: - Setup
    // =========================================================

    func subscribe(
        to content: RealityViewContent
    ) {

        // =====================================================
        // Manipulation began
        // =====================================================

        manipulationSubscription =
            content.subscribe(
                to:
                    ManipulationEvents
                    .WillBegin
                    .self
            ) { [weak self] event in

                guard let self else {
                    return
                }

                self.handleManipulationBegan(
                    event
                )
            }


        // =====================================================
        // Manipulation updated
        // =====================================================

        transformSubscription =
            content.subscribe(
                to:
                    ManipulationEvents
                    .DidUpdateTransform
                    .self
            ) { [weak self] event in

                guard let self else {
                    return
                }

                self.handleManipulationUpdated(
                    event
                )
            }


        // =====================================================
        // Manipulation released
        // =====================================================

        releaseSubscription =
            content.subscribe(
                to:
                    ManipulationEvents
                    .WillRelease
                    .self
            ) { [weak self] event in

                guard let self else {
                    return
                }

                self.handleManipulationReleased(
                    event
                )
            }
    }


    // =========================================================
    // MARK: - Manipulation began
    // =========================================================

    private func handleManipulationBegan(
        _ event: ManipulationEvents.WillBegin
    ) {

        guard
            let entity =
                event.entity as? ModelEntity
        else {
            return
        }


        // =====================================================
        // CASE 1
        //
        // Invisible overlap target
        // =====================================================

        if overlapTargets.contains(
            where: {
                $0 === entity
            }
        ) {

            guard
                !isDraggingOriginal,
                !isDraggingMovableSphere,
                !isDraggingOverlap
            else {
                return
            }


            guard
                let overlapComponent =
                    entity.components[
                        OverlapVisualComponent.self
                    ]
            else {
                return
            }


            guard
                let overlap =
                    overlapSystem
                    .checkOverlap(
                        spheres:
                            movableSpheres
                    )
                    .first(
                        where: {
                            $0.key ==
                            overlapComponent.overlapKey
                        }
                    )
            else {

                print(
                    "⚠️ OVERLAP NO LONGER EXISTS"
                )

                return
            }


            print(
                "🎨 OVERLAP PINCH BEGAN"
            )

            print(
                "🎨 MIXED COLOR:",
                overlap.color
            )


            // -------------------------------------------------
            // Create mixed sphere.
            // -------------------------------------------------

            let mixedSphere =
                createMixedSphere(
                    overlap:
                        overlap
                )


            activeOverlapTarget =
                entity

            activeMixedSphere =
                mixedSphere

            activeOverlap =
                overlap

            isDraggingOverlap =
                true


            print(
                "✨ MIXED SPHERE CREATED"
            )

            print(
                "🟣 MIXED SPHERE IS NOW ACTIVE"
            )

            return
        }


        // =====================================================
        // CASE 2
        //
        // Permanent RGB original
        // =====================================================

        if let original =
            entity.components[
                OriginalSphereComponent.self
            ] {

            guard
                !isDraggingOriginal,
                !isDraggingMovableSphere,
                !isDraggingOverlap
            else {
                return
            }


            activeOriginal =
                entity

            activeOriginalPosition =
                original.fixedPosition

            activeClone =
                nil

            isDraggingOriginal =
                true


            print(
                "🎯 ORIGINAL GRABBED"
            )

            print(
                "🎯 COLOR:",
                original.color
            )


            // -------------------------------------------------
            // Create independent clone.
            // -------------------------------------------------

            let clone =
                createClone(
                    from:
                        entity
                )


            clone.position =
                entity.position


            entity.parent?.addChild(
                clone
            )


            // -------------------------------------------------
            // Clone is a REAL movable sphere.
            // -------------------------------------------------

            movableSpheres.append(
                clone
            )


            activeClone =
                clone


            print(
                "✨ CLONE CREATED"
            )

            return
        }


        // =====================================================
        // CASE 3
        //
        // Existing movable sphere
        //
        // Includes:
        //
        // - clones
        // - mixed spheres
        // =====================================================

        guard
            movableSpheres.contains(
                where: {
                    $0 === entity
                }
        )
        else {
            return
        }


        guard
            !isDraggingOriginal,
            !isDraggingMovableSphere,
            !isDraggingOverlap
        else {
            return
        }


        activeMovableSphere =
            entity

        isDraggingMovableSphere =
            true


        print(
            "🟣 MOVABLE SPHERE GRABBED"
        )
    }


    // =========================================================
    // MARK: - Manipulation updated
    // =========================================================

    private func handleManipulationUpdated(
        _ event: ManipulationEvents.DidUpdateTransform
    ) {

        guard
            let entity =
                event.entity as? ModelEntity
        else {
            return
        }


        // =====================================================
        // CASE 1
        //
        // Permanent original
        // =====================================================

        if isDraggingOriginal {

            guard
                let original =
                    activeOriginal,

                let fixedPosition =
                    activeOriginalPosition,

                event.entity ===
                    original
            else {
                return
            }


            original.position =
                fixedPosition


            // -------------------------------------------------
            // Clone follows the original while it is being
            // manipulated.
            // -------------------------------------------------

            if let clone =
                activeClone {

                clone.position =
                    original.position
            }

            return
        }


        // =====================================================
        // CASE 2
        //
        // Normal movable sphere
        //
        // RealityKit controls its transform.
        // =====================================================

        if isDraggingMovableSphere {

            guard
                let sphere =
                    activeMovableSphere,

                event.entity ===
                    sphere
            else {
                return
            }


            // RealityKit controls the movement.

            return
        }


        // =====================================================
        // CASE 3
        //
        // Invisible overlap target
        // =====================================================

        if isDraggingOverlap {

            guard
                let target =
                    activeOverlapTarget,

                let mixedSphere =
                    activeMixedSphere,

                event.entity ===
                    target
            else {
                return
            }


            if let parent =
                target.parent {

                mixedSphere.position =
                    parent.convert(
                        position:
                            target.position,
                        from:
                            target.parent
                    )

            } else {

                mixedSphere.position =
                    target.position
            }

            return
        }
    }


    // =========================================================
    // MARK: - Manipulation released
    // =========================================================

    private func handleManipulationReleased(
        _ event: ManipulationEvents.WillRelease
    ) {

        guard
            let entity =
                event.entity as? ModelEntity
        else {
            return
        }


        // =====================================================
        // CASE 1
        //
        // Original released
        // =====================================================

        if isDraggingOriginal {

            guard
                let original =
                    activeOriginal,

                event.entity ===
                    original
            else {
                return
            }


            print(
                "🔵 ORIGINAL RELEASE"
            )


            // -------------------------------------------------
            // Restore permanent original.
            // -------------------------------------------------

            if let fixedPosition =
                activeOriginalPosition {

                original.position =
                    fixedPosition
            }


            // -------------------------------------------------
            // Clone stays at release position.
            // -------------------------------------------------

            if let clone =
                activeClone {

                clone.isEnabled =
                    true

                print(
                    "✨ CLONE RELEASED"
                )

                print(
                    "Clone position:",
                    clone.position
                )
            }


            print(
                "Original remains fixed."
            )


            activeOriginal =
                nil

            activeOriginalPosition =
                nil

            activeClone =
                nil

            isDraggingOriginal =
                false


            updateOverlapTargets()

            return
        }


        // =====================================================
        // CASE 2
        //
        // Movable sphere released
        // =====================================================

        if isDraggingMovableSphere {

            guard
                let sphere =
                    activeMovableSphere,

                event.entity ===
                    sphere
            else {
                return
            }


            print(
                "🟣 MOVABLE SPHERE RELEASE"
            )

            print(
                "🎨 FINAL POSITION:",
                sphere.position(
                    relativeTo:
                        nil
                )
            )


            activeMovableSphere =
                nil

            isDraggingMovableSphere =
                false


            updateOverlapTargets()

            return
        }


        // =====================================================
        // CASE 3
        //
        // Invisible overlap target released
        // =====================================================

        if isDraggingOverlap {

            guard
                let target =
                    activeOverlapTarget,

                event.entity ===
                    target
            else {
                return
            }


            print(
                "🎨 OVERLAP RELEASE"
            )


            // -------------------------------------------------
            // Preserve final mixed-sphere position.
            // -------------------------------------------------

            if let mixedSphere =
                activeMixedSphere {

                if let parent =
                    target.parent {

                    mixedSphere.position =
                        parent.convert(
                            position:
                                target.position,
                            from:
                                target.parent
                        )

                } else {

                    mixedSphere.position =
                        target.position
                }


                mixedSphere.isEnabled =
                    true


                print(
                    "🎨 MIXED SPHERE FINAL POSITION:",
                    mixedSphere.position(
                        relativeTo:
                            nil
                    )
                )

                print(
                    "🟣 MIXED SPHERE IS NOW MOVABLE"
                )
            }


            // -------------------------------------------------
            // Remove ONLY invisible target.
            // -------------------------------------------------

            target.removeFromParent()


            overlapTargets.removeAll {
                $0 === target
            }


            activeOverlapTarget =
                nil

            activeMixedSphere =
                nil

            activeOverlap =
                nil

            isDraggingOverlap =
                false


            updateOverlapTargets()

            return
        }
    }


    // =========================================================
    // MARK: - Delete All Movable Spheres
    // =========================================================

    func deleteAllMovableSpheres() {

        print(
            "🗑️ CLEAR ALL"
        )


        // -----------------------------------------------------
        // Remove all REAL movable spheres.
        // -----------------------------------------------------

        for sphere in movableSpheres {

            sphere.removeFromParent()
        }

        movableSpheres.removeAll()


        // -----------------------------------------------------
        // Remove invisible overlap targets.
        // -----------------------------------------------------

        for target in overlapTargets {

            target.removeFromParent()
        }

        overlapTargets.removeAll()


        // -----------------------------------------------------
        // Clear active references.
        // -----------------------------------------------------

        activeClone =
            nil

        activeMovableSphere =
            nil

        activeMixedSphere =
            nil

        activeOverlapTarget =
            nil

        activeOverlap =
            nil


        // -----------------------------------------------------
        // Reset interaction state.
        // -----------------------------------------------------

        isDraggingMovableSphere =
            false

        isDraggingOverlap =
            false


        print(
            "🗑️ ALL CLONES AND MIXED SPHERES DELETED"
        )

        print(
            "🔴🟢🔵 PERMANENT SPHERES REMAIN"
        )
    }


    // =========================================================
    // MARK: - Update Overlap Targets
    // =========================================================

    private func updateOverlapTargets() {

        guard
            !isDraggingOriginal,
            !isDraggingOverlap
        else {
            return
        }


        // =====================================================
        // Find overlaps between REAL movable spheres.
        // =====================================================

        let overlaps =
            overlapSystem.checkOverlap(
                spheres:
                    movableSpheres
            )


        // =====================================================
        // Debug
        // =====================================================

        for overlap in overlaps {

            print(
                "🟣 OVERLAP DETECTED:"
            )

            print(
                "   \(overlap.key)"
            )

            print(
                "   Mixed color:",
                overlap.color
            )
        }


        // =====================================================
        // Current overlap keys
        // =====================================================

        let currentKeys =
            Set(
                overlaps.map {
                    $0.key
                }
            )


        // =====================================================
        // Remove obsolete targets
        // =====================================================

        overlapTargets.removeAll {
            target in

            guard
                let component =
                    target.components[
                        OverlapVisualComponent.self
                    ]
            else {

                target.removeFromParent()

                return true
            }


            if !currentKeys.contains(
                component.overlapKey
            ) {

                target.removeFromParent()

                print(
                    "🗑️ OVERLAP TARGET REMOVED"
                )

                return true
            }

            return false
        }


        // =====================================================
        // Create / update targets
        // =====================================================

        for overlap in overlaps {


            // =================================================
            // Existing target
            // =================================================

            if let existingTarget =
                overlapTargets.first(
                    where: {
                        target in

                        target.components[
                            OverlapVisualComponent.self
                        ]?.overlapKey ==
                            overlap.key
                    }
                ) {


                if let parent =
                    existingTarget.parent {

                    existingTarget.position =
                        parent.convert(
                            position:
                                overlap.position,
                            from:
                                nil
                        )

                } else {

                    existingTarget.position =
                        overlap.position
                }


                existingTarget.components.set(
                    OverlapVisualComponent(
                        overlapKey:
                            overlap.key,

                        mixedColor:
                            overlap.color
                    )
                )


                continue
            }


            // =================================================
            // New invisible target
            // =================================================

            let target =
                ModelEntity()


            target.name =
                "OverlapTarget_\(overlap.key)"


            // -------------------------------------------------
            // Position target at overlap.
            // -------------------------------------------------

            if let parent =
                overlap.firstSphere.parent {

                target.position =
                    parent.convert(
                        position:
                            overlap.position,
                        from:
                            nil
                    )

                parent.addChild(
                    target
                )

            } else {

                continue
            }


            // -------------------------------------------------
            // Collision
            // -------------------------------------------------

            target.components.set(
                CollisionComponent(
                    shapes: [
                        .generateSphere(
                            radius:
                                overlapHitRadius
                        )
                    ]
                )
            )


            // -------------------------------------------------
            // Input
            // -------------------------------------------------

            target.components.set(
                InputTargetComponent()
            )


            // -------------------------------------------------
            // Store overlap information.
            // -------------------------------------------------

            target.components.set(
                OverlapVisualComponent(
                    overlapKey:
                        overlap.key,

                    mixedColor:
                        overlap.color
                )
            )


            // -------------------------------------------------
            // Manipulation
            // -------------------------------------------------

            var manipulation =
                ManipulationComponent()

            manipulation.releaseBehavior =
                .stay

            target.components.set(
                manipulation
            )


            // -------------------------------------------------
            // Target only goes into overlapTargets.
            // -------------------------------------------------

            overlapTargets.append(
                target
            )


            print(
                "🟣 INVISIBLE OVERLAP TARGET CREATED"
            )

            print(
                "Target:",
                target.name
            )

            print(
                "Mixed RGB:",
                overlap.color
            )
        }
    }


    // =========================================================
    // MARK: - Create Clone
    // =========================================================

    private func createClone(
        from original: ModelEntity
    ) -> ModelEntity {

        let color =
            original.components[
                RGBColorComponent.self
            ]?.color ??
            RGBColor.red


        // =====================================================
        // Create clone core
        // =====================================================

        let clone =
            ModelEntity(
                mesh:
                    .generateSphere(
                        radius:
                            sphereRadius
                    ),

                materials: [
                    makeRGBMaterial(
                        color:
                            color.uiColor
                    )
                ]
            )


        clone.name =
            "Clone"


        // =====================================================
        // Preserve RGB information.
        // =====================================================

        clone.components.set(
            RGBColorComponent(
                color:
                    color
            )
        )


        // =====================================================
        // IMPORTANT:
        //
        // Give the clone the same radiating light as the
        // permanent sphere.
        // =====================================================

        addRadiatingGlow(
            to:
                clone,

            color:
                color.uiColor
        )


        // =====================================================
        // Configure interaction.
        // =====================================================

        configureSphereForInteraction(
            clone
        )


        return clone
    }


    // =========================================================
    // MARK: - Create Mixed Sphere
    // =========================================================

    private func createMixedSphere(
        overlap: SphereOverlap
    ) -> ModelEntity {

        let mixedSphere =
            ModelEntity(
                mesh:
                    .generateSphere(
                        radius:
                            sphereRadius
                    ),

                materials: [
                    makeRGBMaterial(
                        color:
                            overlap.color.uiColor
                    )
                ]
            )


        mixedSphere.name =
            "MixedSphere"


        // =====================================================
        // Store MIXED RGB color.
        // =====================================================

        mixedSphere.components.set(
            RGBColorComponent(
                color:
                    overlap.color
            )
        )


        // =====================================================
        // IMPORTANT:
        //
        // The mixed sphere gets a glow using the mixed color.
        //
        // Example:
        //
        // red + green → yellow glow
        // red + blue  → magenta glow
        // green + blue → cyan glow
        // =====================================================

        addRadiatingGlow(
            to:
                mixedSphere,

            color:
                overlap.color.uiColor
        )


        // =====================================================
        // Configure interaction.
        // =====================================================

        configureSphereForInteraction(
            mixedSphere
        )


        // =====================================================
        // Place at overlap midpoint.
        // =====================================================

        if let parent =
            overlap.firstSphere.parent {

            mixedSphere.position =
                parent.convert(
                    position:
                        overlap.position,
                    from:
                        nil
                )

            parent.addChild(
                mixedSphere
            )
        }


        // =====================================================
        // Mixed sphere is a REAL movable sphere.
        // =====================================================

        movableSpheres.append(
            mixedSphere
        )


        return mixedSphere
    }
}
