import ARKit
import RealityKit
import SwiftUI

/// Owns the ARKit session and the RealityKit entities used to draw both hands.
@MainActor
@Observable
final class HandSkeletonVisualizer {
    let rootEntity = Entity()

    private(set) var leftRotationDegrees: Float?
    private(set) var rightRotationDegrees: Float?

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
        leftRotationDegrees = nil
        rightRotationDegrees = nil
    }

    private func updateHand(using anchor: HandAnchor) {
        let hand = anchor.chirality == .left ? leftHand : rightHand

        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            hand.setVisible(false)
            return
        }

        hand.update(anchorTransform: anchor.originFromAnchorTransform,
                    skeleton: skeleton)
        updateHorizontalRotation(for: anchor, skeleton: skeleton)
    }

    /// Measures forearm pronation/supination around the elbow-to-wrist axis.
    /// Thumb-up is 0°, palm-down is -90°, and palm-up is +90°.
    private func updateHorizontalRotation(for anchor: HandAnchor,
                                          skeleton: HandSkeleton) {
        let forearmArm = skeleton.joint(.forearmArm)
        let forearmWrist = skeleton.joint(.forearmWrist)
        let index = skeleton.joint(.indexFingerKnuckle)
        let little = skeleton.joint(.littleFingerKnuckle)

        guard forearmArm.isTracked,
              forearmWrist.isTracked,
              index.isTracked,
              little.isTracked else { return }

        let worldFromArm = anchor.originFromAnchorTransform
            * forearmArm.anchorFromJointTransform
        let worldFromForearmWrist = anchor.originFromAnchorTransform
            * forearmWrist.anchorFromJointTransform
        let worldFromIndex = anchor.originFromAnchorTransform
            * index.anchorFromJointTransform
        let worldFromLittle = anchor.originFromAnchorTransform
            * little.anchorFromJointTransform

        let armPosition = worldFromArm.position
        let wristPosition = worldFromForearmWrist.position
        var forearmAxis = wristPosition - armPosition
        let axisLength = simd_length(forearmAxis)
        guard axisLength > 0.0001 else { return }
        forearmAxis /= axisLength

        let towardIndex = worldFromIndex.position - wristPosition
        let towardLittle = worldFromLittle.position - wristPosition
        var palmNormal = simd_cross(towardIndex, towardLittle)

        // Mirrored joint order reverses the cross product on the left hand.
        if anchor.chirality == .left {
            palmNormal *= -1
        }

        // Remove any component along the forearm, leaving only its twist direction.
        palmNormal -= simd_dot(palmNormal, forearmAxis) * forearmAxis
        let palmNormalLength = simd_length(palmNormal)
        guard palmNormalLength > 0.0001 else { return }
        palmNormal /= palmNormalLength

        let worldUp = SIMD3<Float>(0, 1, 0)
        var neutralPalmDirection = simd_cross(worldUp, forearmAxis)
        if anchor.chirality == .left {
            neutralPalmDirection *= -1
        }

        let neutralLength = simd_length(neutralPalmDirection)
        guard neutralLength > 0.0001 else { return }
        neutralPalmDirection /= neutralLength

        let sine = simd_dot(forearmAxis,
                            simd_cross(neutralPalmDirection, palmNormal))
        let cosine = simd_dot(neutralPalmDirection, palmNormal)
        var degrees = atan2(sine, cosine) * 180 / .pi

        // Keep the clinical sign convention identical for both hands.
        if anchor.chirality == .left {
            degrees *= -1
        }

        setAngle(degrees, for: anchor.chirality)
    }

    private func setAngle(_ degrees: Float, for chirality: HandAnchor.Chirality) {
        if chirality == .left {
            leftRotationDegrees = degrees
        } else {
            rightRotationDegrees = degrees
        }
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
