//
//  LightDialController.swift
//  RGB
//

import ARKit
import RealityKit
import simd

@MainActor
final class LightDialController {

    typealias TargetProvider = (SIMD3<Float>) -> ModelEntity?
    typealias IntensityApplier = (ModelEntity, Float) -> Void

    private let targetProvider: TargetProvider
    private let intensityApplier: IntensityApplier

    private var activeHandID: UUID?
    private weak var activeTarget: ModelEntity?
    private var initialAngle: Float = 0
    private var initialIntensity: Float = SphereLightComponent.defaultIntensity
    private var smoothedIntensity: Float = SphereLightComponent.defaultIntensity

    private let pinchStartDistance: Float = 0.035
    private let pinchEndDistance: Float = 0.055
    private let angleDeadZone: Float = 0.035
    private let intensityPerRadian: Float = 0.32
    private let smoothingAmount: Float = 0.28

    init(
        targetProvider: @escaping TargetProvider,
        intensityApplier: @escaping IntensityApplier
    ) {
        self.targetProvider = targetProvider
        self.intensityApplier = intensityApplier
    }

    func process(anchor: HandAnchor) {
        guard anchor.isTracked,
              let sample = HandDialSample(anchor: anchor) else {
            endDialIfNeeded(for: anchor.id)
            return
        }

        if let activeHandID, activeHandID != anchor.id {
            return
        }

        if sample.pinchDistance <= pinchStartDistance {
            if activeTarget == nil {
                beginDial(with: sample, handID: anchor.id)
            } else {
                updateDial(with: sample)
            }
        } else if sample.pinchDistance >= pinchEndDistance {
            endDialIfNeeded(for: anchor.id)
        }
    }

    func cancelDial() {
        activeHandID = nil
        activeTarget = nil
    }

    private func beginDial(
        with sample: HandDialSample,
        handID: UUID
    ) {
        guard let target = targetProvider(sample.pinchCenter) else {
            return
        }

        activeHandID = handID
        activeTarget = target
        initialAngle = sample.angle
        initialIntensity = target.components[SphereLightComponent.self]?.intensity
            ?? SphereLightComponent.defaultIntensity
        smoothedIntensity = initialIntensity
    }

    private func updateDial(with sample: HandDialSample) {
        guard let activeTarget else {
            return
        }

        let rawDelta = normalizedAngle(sample.angle - initialAngle)
        let adjustedDelta: Float = abs(rawDelta) < angleDeadZone ? 0 : -rawDelta
        let targetIntensity = clamp(
            initialIntensity + (adjustedDelta * intensityPerRadian)
        )
        let nextIntensity = smoothedIntensity
            + ((targetIntensity - smoothedIntensity) * smoothingAmount)

        smoothedIntensity = nextIntensity
        intensityApplier(activeTarget, nextIntensity)
    }

    private func endDialIfNeeded(for handID: UUID) {
        guard activeHandID == handID else {
            return
        }

        cancelDial()
    }

    private func normalizedAngle(_ angle: Float) -> Float {
        var result = angle

        while result > .pi {
            result -= 2.0 * .pi
        }

        while result < -.pi {
            result += 2.0 * .pi
        }

        return result
    }

    private func clamp(_ value: Float) -> Float {
        min(
            max(value, SphereLightComponent.minimumIntensity),
            SphereLightComponent.maximumIntensity
        )
    }
}

private struct HandDialSample {
    let pinchCenter: SIMD3<Float>
    let pinchDistance: Float
    let angle: Float

    init?(anchor: HandAnchor) {
        guard let skeleton = anchor.handSkeleton else {
            return nil
        }

        let thumbTip = skeleton.joint(.thumbTip)
        let indexTip = skeleton.joint(.indexFingerTip)
        let wrist = skeleton.joint(.wrist)

        guard thumbTip.isTracked,
              indexTip.isTracked,
              wrist.isTracked else {
            return nil
        }

        let thumbPosition = Self.worldPosition(
            for: thumbTip,
            in: anchor
        )
        let indexPosition = Self.worldPosition(
            for: indexTip,
            in: anchor
        )
        let wristPosition = Self.worldPosition(
            for: wrist,
            in: anchor
        )

        let pinchCenter = (thumbPosition + indexPosition) / 2.0
        let dialVector = pinchCenter - wristPosition

        guard simd_length(dialVector) > 0.01 else {
            return nil
        }

        self.pinchCenter = pinchCenter
        self.pinchDistance = simd_distance(thumbPosition, indexPosition)
        self.angle = atan2(dialVector.y, dialVector.x)
    }

    private static func worldPosition(
        for joint: HandSkeleton.Joint,
        in anchor: HandAnchor
    ) -> SIMD3<Float> {
        let transform = anchor.originFromAnchorTransform
            * joint.anchorFromJointTransform
        return SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
    }
}
