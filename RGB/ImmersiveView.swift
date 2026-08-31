//
//  ImmersiveView.swift
//  RGB
//
//  Created by Minjae Son on 8/10/26.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @StateObject private var interactionManager = SphereInteractionManager()
    @StateObject private var handTrackingManager = HandTrackingManager()

    var body: some View {
        RealityView { content, attachments in
            // Register custom components before using them.
            RGBColorComponent.registerComponent()
            OriginalSphereComponent.registerComponent()
            OverlapVisualComponent.registerComponent()
            SphereLightComponent.registerComponent()

            let headAnchor = AnchorEntity(.head)

            let red = makeRGBSphere(color: .red, rgbColor: .red)
            let green = makeRGBSphere(color: .green, rgbColor: .green)
            let blue = makeRGBSphere(color: .blue, rgbColor: .blue)

            red.position = SIMD3(0.0, 0.25, -1.5)
            green.position = SIMD3(-0.3, -0.15, -1.5)
            blue.position = SIMD3(0.3, -0.15, -1.5)

            // Keep the original spheres fixed at their starting positions.
            red.components.set(OriginalSphereComponent(color: .red, fixedPosition: red.position))
            green.components.set(OriginalSphereComponent(color: .green, fixedPosition: green.position))
            blue.components.set(OriginalSphereComponent(color: .blue, fixedPosition: blue.position))

            configureSphereForInteraction(red)
            configureSphereForInteraction(green)
            configureSphereForInteraction(blue)

            interactionManager.setOriginalSpheres([red, green, blue])

            let lightDialController = RightHandLightDialController { worldPosition in
                if let selectedSphere = interactionManager.selectedLightSphere() {
                    return selectedSphere
                }

                guard let sphere = interactionManager.closestLightSphere(
                    to: worldPosition
                ) else {
                    return nil
                }

                interactionManager.selectLightSphere(sphere)
                return sphere
            } intensityApplier: { sphere, intensity in
                interactionManager.setLightIntensity(
                    intensity,
                    for: sphere
                )
            }

            handTrackingManager.connectLightDialController(
                lightDialController
            )

            headAnchor.addChild(red)
            headAnchor.addChild(green)
            headAnchor.addChild(blue)

            // Attach the Clear All button to the same head anchor.
            if let clearButton = attachments.entity(for: "clearAllButton") {
                clearButton.position = SIMD3(0.0, -0.40, -1.2)
                headAnchor.addChild(clearButton)
            }

            content.add(headAnchor)

            // The manager handles RealityKit manipulation events.
            interactionManager.subscribe(to: content)
        } attachments: {
            Attachment(id: "clearAllButton") {
                Button {
                    interactionManager.deleteAllMovableSpheres()
                } label: {
                    Text("Clear All")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task {
            await handTrackingManager.start()
        }
        .onDisappear {
            handTrackingManager.stop()
        }
    }
}

#Preview {
    ImmersiveView()
}
