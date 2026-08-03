import ARKit
import RealityKit
import Observation

@Observable
@MainActor
final class HandTrackingManager {
    /// 오른손 검지 끝의 월드 좌표. 손이 안 보이면 nil.
    private(set) var indexTipPosition: SIMD3<Float>?

    /// 핀치 정도. 0 = 손가락 벌림, 1 = 엄지·검지 맞닿음.
    private(set) var pinchAmount: Float = 0

    private let session = ARKitSession()
    private let provider = HandTrackingProvider()

    func start() async {
        guard HandTrackingProvider.isSupported else {
            print("핸드 트래킹 미지원 (시뮬레이터?)")
            return
        }
        do {
            try await session.run([provider])
        } catch {
            print("ARKit 세션 시작 실패: \(error)")
            return
        }

        for await update in provider.anchorUpdates {
            let anchor = update.anchor
            guard anchor.chirality == .right,
                  anchor.isTracked,
                  let skeleton = anchor.handSkeleton
            else {
                if update.anchor.chirality == .right {
                    indexTipPosition = nil
                    pinchAmount = 0
                }
                continue
            }

            let indexTip = worldPosition(of: skeleton.joint(.indexFingerTip),
                                         in: anchor)
            let thumbTip = worldPosition(of: skeleton.joint(.thumbTip),
                                         in: anchor)

            indexTipPosition = indexTip

            // 엄지-검지 거리 8cm(벌림) ~ 1cm(맞닿음)를 0...1로 정규화
            let dist = distance(indexTip, thumbTip)
            pinchAmount = 1 - min(max((dist - 0.01) / 0.07, 0), 1)
        }
    }

    private func worldPosition(of joint: HandSkeleton.Joint,
                               in anchor: HandAnchor) -> SIMD3<Float> {
        let world = anchor.originFromAnchorTransform
            * joint.anchorFromJointTransform
        return SIMD3(world.columns.3.x, world.columns.3.y, world.columns.3.z)
    }
}
