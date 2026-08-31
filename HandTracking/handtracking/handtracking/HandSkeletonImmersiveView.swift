import RealityKit
import SwiftUI

struct HandSkeletonImmersiveView: View {
    @State private var visualizer = HandSkeletonVisualizer()

    var body: some View {
        RealityView { content in
            content.add(visualizer.rootEntity)
            visualizer.start()
        }
        .onDisappear {
            visualizer.stop()
        }
    }
}

