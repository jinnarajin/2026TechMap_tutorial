//
//  LightDialController.swift
//  RGB
//

import ARKit
import Foundation
import RealityKit
import simd

@MainActor
final class LightDialController {

    typealias TargetProvider = (SIMD3<Float>) -> ModelEntity?
    typealias TargetSelector = (ModelEntity) -> Void
    typealias IntensityApplier = (ModelEntity, Float) -> Void

    private enum DialState {
        case idle
        case candidate(
            handID: UUID,
            target: ModelEntity,
            startedAt: TimeInterval
        )
        case adjusting(
            handID: UUID,
            target: ModelEntity
        )
    }

    private let targetProvider: TargetProvider
    private let targetSelector: TargetSelector
    private let intensityApplier: IntensityApplier

    private var state: DialState = .idle
    private var initialPalmAxis = SIMD3<Float>(1, 0, 0)
    private var rotationAxis = SIMD3<Float>(0, 0, 1)
    private var initialIntensity: Float = SphereLightComponent.defaultIntensity
    private var smoothedIntensity: Float = SphereLightComponent.defaultIntensity

    private let activationDistance: Float = 0.30
    private let releaseDistance: Float = 0.40
    private let openPalmHoldDuration: TimeInterval = 0.30
    private let angleDeadZone: Float = .pi / 36.0
    private let intensityPerRadian: Float = 0.32
    private let smoothingAmount: Float = 0.35
    private let rotationDirection: Float = -1.0

    init(
        targetProvider: @escaping TargetProvider,
        targetSelector: @escaping TargetSelector,
        intensityApplier: @escaping IntensityApplier
    ) {
        self.targetProvider = targetProvider
        self.targetSelector = targetSelector
        self.intensityApplier = intensityApplier
    }

    func process(anchor: HandAnchor) {
        guard anchor.isTracked,
              let sample = HandDialSample(anchor: anchor) else {
            cancelDial()
            return
        }

        let now = ProcessInfo.processInfo.systemUptime

        switch state {
        case .idle:
            guard sample.isOpenPalm,
                  let target = targetProvider(sample.palmCenter),
                  distance(from: sample, to: target) <= activationDistance
            else {
                return
            }

            state = .candidate(
                handID: anchor.id,
                target: target,
                startedAt: now
            )

        case let .candidate(handID, target, startedAt):
            guard handID == anchor.id else {
                return
            }

            guard sample.isOpenPalm,
                  distance(from: sample, to: target) <= releaseDistance
            else {
                cancelDial()
                return
            }

            guard now - startedAt >= openPalmHoldDuration else {
                return
            }

            beginDial(with: sample, handID: handID, target: target)

        case let .adjusting(handID, target):
            guard handID == anchor.id else {
                return
            }

            guard sample.isOpenPalm,
                  distance(from: sample, to: target) <= releaseDistance
            else {
                cancelDial()
                return
            }

            updateDial(with: sample, target: target)
        }
    }

    func cancelDial() {
        state = .idle
    }

    private func beginDial(
        with sample: HandDialSample,
        handID: UUID,
        target: ModelEntity
    ) {
        targetSelector(target)
        state = .adjusting(handID: handID, target: target)
        initialPalmAxis = sample.palmAxis
        rotationAxis = normalized(
            target.position(relativeTo: nil) - sample.palmCenter
        )
        initialIntensity = target.components[SphereLightComponent.self]?.intensity
            ?? SphereLightComponent.defaultIntensity
        smoothedIntensity = initialIntensity
    }

    private func updateDial(
        with sample: HandDialSample,
        target: ModelEntity
    ) {
        let rawDelta = signedAngle(
            from: initialPalmAxis,
            to: sample.palmAxis,
            around: rotationAxis
        )
        let adjustedDelta: Float = abs(rawDelta) < angleDeadZone
            ? 0
            : rawDelta * rotationDirection
        let targetIntensity = clamp(
            initialIntensity + (adjustedDelta * intensityPerRadian)
        )
        let nextIntensity = smoothedIntensity
            + ((targetIntensity - smoothedIntensity) * smoothingAmount)

        smoothedIntensity = nextIntensity
        intensityApplier(target, nextIntensity)
    }

    private func distance(
        from sample: HandDialSample,
        to target: ModelEntity
    ) -> Float {
        simd_distance(sample.palmCenter, target.position(relativeTo: nil))
    }

    private func signedAngle(
        from initialAxis: SIMD3<Float>,
        to currentAxis: SIMD3<Float>,
        around axis: SIMD3<Float>
    ) -> Float {
        let initial = normalized(
            initialAxis - (axis * simd_dot(initialAxis, axis))
        )
        let current = normalized(
            currentAxis - (axis * simd_dot(currentAxis, axis))
        )

        guard simd_length(initial) > 0.001,
              simd_length(current) > 0.001 else {
            return 0
        }

        let sine = simd_dot(axis, simd_cross(initial, current))
        let cosine = simd_dot(initial, current)

        return atan2(sine, cosine)
    }

    private func clamp(_ value: Float) -> Float {
        min(
            max(value, SphereLightComponent.minimumIntensity),
            SphereLightComponent.maximumIntensity
        )
    }

    private func normalized(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(vector)

        guard length > 0.001 else {
            return SIMD3<Float>(0, 0, 1)
        }

        return vector / length
    }
}

private struct HandDialSample {
    let palmCenter: SIMD3<Float>
    let palmAxis: SIMD3<Float>
    let isOpenPalm: Bool

    init?(anchor: HandAnchor) {
        guard let skeleton = anchor.handSkeleton else {
            return nil
        }

        let wrist = skeleton.joint(.wrist)
        let indexKnuckle = skeleton.joint(.indexFingerKnuckle)
        let middleKnuckle = skeleton.joint(.middleFingerKnuckle)
        let ringKnuckle = skeleton.joint(.ringFingerKnuckle)
        let littleKnuckle = skeleton.joint(.littleFingerKnuckle)
        let indexTip = skeleton.joint(.indexFingerTip)
        let middleTip = skeleton.joint(.middleFingerTip)
        let ringTip = skeleton.joint(.ringFingerTip)

        guard wrist.isTracked,
              indexKnuckle.isTracked,
              middleKnuckle.isTracked,
              ringKnuckle.isTracked,
              littleKnuckle.isTracked,
              indexTip.isTracked,
              middleTip.isTracked,
              ringTip.isTracked else {
            return nil
        }

        let wristPosition = Self.worldPosition(
            for: wrist,
            in: anchor
        )
        let indexKnucklePosition = Self.worldPosition(
            for: indexKnuckle,
            in: anchor
        )
        let middleKnucklePosition = Self.worldPosition(
            for: middleKnuckle,
            in: anchor
        )
        let ringKnucklePosition = Self.worldPosition(
            for: ringKnuckle,
            in: anchor
        )
        let littleKnucklePosition = Self.worldPosition(
            for: littleKnuckle,
            in: anchor
        )
        let indexTipPosition = Self.worldPosition(
            for: indexTip,
            in: anchor
        )
        let middleTipPosition = Self.worldPosition(
            for: middleTip,
            in: anchor
        )
        let ringTipPosition = Self.worldPosition(
            for: ringTip,
            in: anchor
        )

        let palmWidth = simd_distance(
            indexKnucklePosition,
            littleKnucklePosition
        )

        guard palmWidth > 0.02 else {
            return nil
        }

        let palmAxis = littleKnucklePosition - indexKnucklePosition

        guard simd_length(palmAxis) > 0.001 else {
            return nil
        }

        self.palmCenter = (
            wristPosition
            + indexKnucklePosition
            + middleKnucklePosition
            + littleKnucklePosition
        ) / 4.0
        self.palmAxis = palmAxis / simd_length(palmAxis)
        self.isOpenPalm =
            Self.isFingerExtended(
                tip: indexTipPosition,
                knuckle: indexKnucklePosition,
                wrist: wristPosition,
                palmWidth: palmWidth
            )
            && Self.isFingerExtended(
                tip: middleTipPosition,
                knuckle: middleKnucklePosition,
                wrist: wristPosition,
                palmWidth: palmWidth
            )
            && Self.isFingerExtended(
                tip: ringTipPosition,
                knuckle: ringKnucklePosition,
                wrist: wristPosition,
                palmWidth: palmWidth
            )
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

    private static func isFingerExtended(
        tip: SIMD3<Float>,
        knuckle: SIMD3<Float>,
        wrist: SIMD3<Float>,
        palmWidth: Float
    ) -> Bool {
        let tipFromKnuckle = simd_distance(tip, knuckle)
        let tipFromWrist = simd_distance(tip, wrist)
        let knuckleFromWrist = simd_distance(knuckle, wrist)

        return tipFromKnuckle > palmWidth * 0.45
            && tipFromWrist > knuckleFromWrist + (palmWidth * 0.35)
    }
}
