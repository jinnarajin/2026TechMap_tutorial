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

#if targetEnvironment(simulator)
    @State private var debugLightColor: DebugLightColor = .red
    @State private var debugLightIntensity =
        Double(SphereLightComponent.defaultIntensity)
#endif

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

            let lightDialController = LightDialController { worldPosition in
                interactionManager.closestLightSphere(
                    to: worldPosition
                )
            } targetSelector: { sphere in
                interactionManager.selectLightSphere(sphere)
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

#if targetEnvironment(simulator)
            if let debugControls = attachments.entity(for: "lightDebugControls") {
                debugControls.position = SIMD3<Float>(0.0, -0.58, -1.2)
                headAnchor.addChild(debugControls)
            }
#endif

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

#if targetEnvironment(simulator)
            Attachment(id: "lightDebugControls") {
                VStack(spacing: 12) {
                    Picker("Sphere", selection: $debugLightColor) {
                        ForEach(DebugLightColor.allCases) { color in
                            Text(color.rawValue).tag(color)
                        }
                    }
                    .pickerStyle(.segmented)

                    Slider(
                        value: Binding(
                            get: {
                                Double(
                                    interactionManager.selectedLightIntensity()
                                        ?? Float(debugLightIntensity)
                                )
                            },
                            set: { newValue in
                                debugLightIntensity = newValue
                                interactionManager
                                    .setLightIntensityForSelectedSphere(
                                    Float(newValue),
                                    fallbackOriginalColor: debugLightColor.rgbColor
                                )
                            }
                        ),
                        in: 0...1
                    )

                    Text(handTrackingManager.debugStatus)
                        .font(.caption)
                        .lineLimit(6)
                        .monospacedDigit()
                }
                .frame(width: 360)
                .padding(16)
                .glassBackgroundEffect()
                .onChange(of: debugLightColor) { _, newValue in
                    guard interactionManager.selectedLightSphere() == nil else {
                        return
                    }

                    interactionManager.setLightIntensity(
                        Float(debugLightIntensity),
                        forOriginalColor: newValue.rgbColor
                    )
                }
            }
#endif
        }
        .task {
            await handTrackingManager.start()
        }
        .onDisappear {
            handTrackingManager.stop()
        }
    }
}

#if targetEnvironment(simulator)
private enum DebugLightColor: String, CaseIterable, Identifiable {
    case red = "Red"
    case green = "Green"
    case blue = "Blue"

    var id: Self {
        self
    }

    var rgbColor: RGBColor {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        }
    }
}
#endif

#Preview {
    ImmersiveView()
}
