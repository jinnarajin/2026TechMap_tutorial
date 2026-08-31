import RealityKit
import SwiftUI

struct HandSkeletonImmersiveView: View {
    @State private var visualizer = HandSkeletonVisualizer()

    var body: some View {
        RealityView { content, attachments in
            content.add(visualizer.rootEntity)

            if let anglePanel = attachments.entity(for: "angle-panel") {
                let headAnchor = AnchorEntity(.head)
                anglePanel.position = [0, 0.18, -0.75]
                headAnchor.addChild(anglePanel)
                content.add(headAnchor)
            }

            visualizer.start()
        } attachments: {
            Attachment(id: "angle-panel") {
                HandRotationAnglePanel(visualizer: visualizer)
            }
        }
        .onDisappear {
            visualizer.stop()
        }
    }
}

private struct HandRotationAnglePanel: View {
    let visualizer: HandSkeletonVisualizer

    var body: some View {
        HStack(spacing: 28) {
            angleItem(title: "왼손",
                      angle: visualizer.leftRotationDegrees,
                      color: .cyan)

            Divider()
                .frame(height: 52)

            angleItem(title: "오른손",
                      angle: visualizer.rightRotationDegrees,
                      color: .pink)
        }
        .overlay(alignment: .bottom) {
            Text("손바닥 아래 −90°  ·  엄지 위 0°  ·  손바닥 위 +90°")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .offset(y: 12)
        }
        .padding(.horizontal, 26)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .glassBackgroundEffect()
    }

    private func angleItem(title: String, angle: Float?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)

            Text(angle.map { "\(Int($0.rounded()))°" } ?? "인식 중")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(minWidth: 110)
    }
}
