//
//  ImmersiveView.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {

    // =========================================================
    // MARK: - Interaction manager
    // =========================================================

    @StateObject private var interactionManager =
        SphereInteractionManager()


    // =========================================================
    // MARK: - Configuration
    // =========================================================

    private let sphereRadius:
        Float = 0.15


    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {

        RealityView { content, attachments in

            // =====================================================
            // Register components
            // =====================================================

            RGBColorComponent.registerComponent()

            OriginalSphereComponent.registerComponent()

            OverlapVisualComponent.registerComponent()


            // =====================================================
            // Head anchor
            // =====================================================

            let headAnchor =
                AnchorEntity(.head)


            // =====================================================
            // Permanent RGB spheres
            // =====================================================

            let red =
                makeRGBSphere(
                    color:
                        .red,
                    rgbColor:
                        RGBColor.red
                )


            let green =
                makeRGBSphere(
                    color:
                        .green,
                    rgbColor:
                        RGBColor.green
                )


            let blue =
                makeRGBSphere(
                    color:
                        .blue,
                    rgbColor:
                        RGBColor.blue
                )


            // =====================================================
            // Positions
            //
            // Keep these exactly as before.
            // =====================================================

            red.position =
                SIMD3<Float>(
                    0.0,
                    0.25,
                    -1.5
                )


            green.position =
                SIMD3<Float>(
                    -0.3,
                    -0.15,
                    -1.5
                )


            blue.position =
                SIMD3<Float>(
                    0.3,
                    -0.15,
                    -1.5
                )


            // =====================================================
            // Mark permanent originals
            // =====================================================

            red.components.set(
                OriginalSphereComponent(
                    color:
                        RGBColor.red,

                    fixedPosition:
                        red.position
                )
            )


            green.components.set(
                OriginalSphereComponent(
                    color:
                        RGBColor.green,

                    fixedPosition:
                        green.position
                )
            )


            blue.components.set(
                OriginalSphereComponent(
                    color:
                        RGBColor.blue,

                    fixedPosition:
                        blue.position
                )
            )


            // =====================================================
            // Configure originals
            // =====================================================

            configureSphereForInteraction(
                red
            )

            configureSphereForInteraction(
                green
            )

            configureSphereForInteraction(
                blue
            )


            // =====================================================
            // Add permanent spheres
            // =====================================================

            headAnchor.addChild(
                red
            )

            headAnchor.addChild(
                green
            )

            headAnchor.addChild(
                blue
            )


            // =====================================================
            // Clear All button
            //
            // Same head anchor as the permanent spheres.
            // =====================================================

            if let clearButton =
                attachments.entity(
                    for:
                        "clearAllButton"
                ) {

                clearButton.position =
                    SIMD3<Float>(
                        0.0,
                        -0.40,
                        -1.2
                    )


                headAnchor.addChild(
                    clearButton
                )
            }


            // =====================================================
            // Add head anchor
            // =====================================================

            content.add(
                headAnchor
            )


            // =====================================================
            // Give RealityView event handling to manager
            // =====================================================

            interactionManager.subscribe(
                to:
                    content
            )
        } attachments: {

            // =====================================================
            // Clear All button
            // =====================================================

            Attachment(
                id:
                    "clearAllButton"
            ) {

                Button {

                    interactionManager
                        .deleteAllMovableSpheres()

                } label: {

                    Text(
                        "Clear All"
                    )
                    .font(
                        .headline
                    )
                    .padding(
                        .horizontal,
                        24
                    )
                    .padding(
                        .vertical,
                        12
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
        }
    }
}


// =============================================================
// MARK: - Preview
// =============================================================

#Preview {
    ImmersiveView()
}
