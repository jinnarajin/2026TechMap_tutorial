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

    private let sphereRadius: Float = 0.15

    var body: some View {
        RealityView { content, attachments in
            // Register custom RealityKit components before using them.
            RGBColorComponent.registerComponent()
            OriginalSphereComponent.registerComponent()
            OverlapVisualComponent.registerComponent()

            let headAnchor = AnchorEntity(.head)

            // The three original spheres stay fixed in the scene.
            let red = makeRGBSphere(color: .red, rgbColor: .red)
            let green = makeRGBSphere(color: .green, rgbColor: .green)
            let blue = makeRGBSphere(color: .blue, rgbColor: .blue)

            red.position = SIMD3<Float>(0.0, 0.25, -1.5)
            green.position = SIMD3<Float>(-0.3, -0.15, -1.5)
            blue.position = SIMD3<Float>(0.3, -0.15, -1.5)

            // Store the original position so the sphere can return
            // to its fixed position after manipulation.
            red.components.set(
                OriginalSphereComponent(color: .red, fixedPosition: red.position)
            )

            green.components.set(
                OriginalSphereComponent(color: .green, fixedPosition: green.position)
            )

            blue.components.set(
                OriginalSphereComponent(color: .blue, fixedPosition: blue.position)
            )

            configureSphereForInteraction(red)
            configureSphereForInteraction(green)
            configureSphereForInteraction(blue)

            headAnchor.addChild(red)
            headAnchor.addChild(green)
            headAnchor.addChild(blue)

            // Attach the SwiftUI Clear All button to the same head anchor.
            if let clearButton = attachments.entity(for: "clearAllButton") {
                clearButton.position = SIMD3<Float>(0.0, -0.40, -1.2)
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
    }
}

#Preview {
    ImmersiveView()
}
