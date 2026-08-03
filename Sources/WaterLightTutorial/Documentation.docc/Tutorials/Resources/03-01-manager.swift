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
        }
    }
}
