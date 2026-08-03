import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @State private var handTracking = HandTrackingManager()

    private let waterCenter: SIMD3<Float> = [0, 0.75, -1.5]

    var body: some View {
        RealityView { content in
            let water = makeWaterSurface()
            content.add(water)
            content.add(makeLight())
        } update: { content in
            guard let light = content.entities.first(where: {
                $0.name == "sunLight"
            }) else { return }

            if let hand = handTracking.indexTipPosition {
                // 손 위치보다 1m 위에서 비추되, 부드럽게 따라가기
                let target = hand + SIMD3<Float>(0, 1.0, 0)
                light.position = mix(light.position, target, t: 0.2)
                light.look(at: waterCenter, from: light.position,
                           relativeTo: nil)
            }
        }
        .task {
            await handTracking.start()
        }
    }

    // makeWaterSurface(), makeLight()는 챕터 2와 동일
}
