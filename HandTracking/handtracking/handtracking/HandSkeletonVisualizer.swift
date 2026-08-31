import ARKit
import RealityKit
import SwiftUI

/// Owns the ARKit session and the RealityKit entities used to draw both hands.
@MainActor
@Observable
final class HandSkeletonVisualizer {
    let rootEntity = Entity()

    private let session = ARKitSession()
    private let provider = HandTrackingProvider()
    private let leftHand = SkeletonHandEntity(color: .cyan)
    private let rightHand = SkeletonHandEntity(color: .magenta)
    private var trackingTask: Task<Void, Never>?

    private(set) var errorMessage: String?

    init() {
        rootEntity.addChild(leftHand.root)
        rootEntity.addChild(rightHand.root)
    }

    func start() {
        guard trackingTask == nil else { return }

        guard HandTrackingProvider.isSupported else {
            errorMessage = "이 기기에서는 손 추적을 사용할 수 없습니다."
            return
        }

        trackingTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await session.run([provider])

                for await update in provider.anchorUpdates {
                    guard !Task.isCancelled else { break }
                    updateHand(using: update.anchor)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        trackingTask?.cancel()
        trackingTask = nil
        leftHand.setVisible(false)
        rightHand.setVisible(false)
    }

    private func updateHand(using anchor: HandAnchor) {
        let hand = anchor.chirality == .left ? leftHand : rightHand

        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            hand.setVisible(false)
            return
        }

        hand.update(anchorTransform: anchor.originFromAnchorTransform,
                    skeleton: skeleton)
    }
}

@MainActor
private final class SkeletonHandEntity {
    let root = Entity()

    private let jointRadius: Float = 0.006
    private let boneRadius: Float = 0.0025
    private var joints: [HandSkeleton.JointName: ModelEntity] = [:]
    private var bones: [HandSkeleton.JointName: ModelEntity] = [:]

    init(color: UIColor) {
        let jointMaterial = SimpleMaterial(color: color, isMetallic: false)
        let boneMaterial = SimpleMaterial(color: color.withAlphaComponent(0.72),
                                          isMetallic: false)

        for name in HandSkeleton.JointName.allCases {
            let joint = ModelEntity(
                mesh: .generateSphere(radius: jointRadius),
                materials: [jointMaterial]
            )
            joint.isEnabled = false
            root.addChild(joint)
            joints[name] = joint

            let bone = ModelEntity(
                mesh: .generateCylinder(height: 1, radius: boneRadius),
                materials: [boneMaterial]
            )
            bone.isEnabled = false
            root.addChild(bone)
            bones[name] = bone
        }

        root.isEnabled = false
    }

    func setVisible(_ visible: Bool) {
        root.isEnabled = visible
    }

    func update(anchorTransform: simd_float4x4, skeleton: HandSkeleton) {
        root.isEnabled = true
        root.transform = Transform(matrix: anchorTransform)

        for trackedJoint in skeleton.allJoints {
            let jointEntity = joints[trackedJoint.name]
            jointEntity?.isEnabled = trackedJoint.isTracked

            guard trackedJoint.isTracked else {
                bones[trackedJoint.name]?.isEnabled = false
                continue
            }

            let jointPosition = trackedJoint.anchorFromJointTransform.position
            jointEntity?.position = jointPosition

            guard let parent = trackedJoint.parentJoint,
                  parent.isTracked,
                  let boneEntity = bones[trackedJoint.name] else {
                bones[trackedJoint.name]?.isEnabled = false
                continue
            }

            let parentPosition = parent.anchorFromJointTransform.position
            positionBone(boneEntity, from: parentPosition, to: jointPosition)
        }
    }

    private func positionBone(_ bone: ModelEntity,
                              from start: SIMD3<Float>,
                              to end: SIMD3<Float>) {
        let delta = end - start
        let length = simd_length(delta)

        guard length > 0.0001 else {
            bone.isEnabled = false
            return
        }

        bone.isEnabled = true
        bone.position = (start + end) * 0.5
        bone.scale = SIMD3(1, length, 1)
        bone.orientation = simd_quatf(from: SIMD3(0, 1, 0),
                                      to: delta / length)
    }
}

private extension simd_float4x4 {
    var position: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}

