//
//  RightHandLightDialController.swift
//  RGB
//
//  Copied from LightDialController.swift and rebuilt for right-hand wrist-roll brightness control.
//

import ARKit
import RealityKit
import simd

struct RightHandLightDebugState {
    var isRightHandTracked = false
    var isWristTracked = false
    var areFingersExtended = false
    var hasForearmOrElbowTracking = false
    var rollDegrees: Float = 0
    var normalizedBrightness: Float = 0
    var lightIntensity: Float = SphereLightComponent.defaultIntensity
    var trackedJointCount = 0
    var status = "오른손 추적 대기 중"
    var extra = "오른손을 모두 펼쳐 손목을 뒤집어주세요."

    var lines: [String] {
        [
            "오른손: \(isRightHandTracked ? "인식됨" : "인식 안됨")",
            "손목: \(isWristTracked ? "인식됨" : "인식 안됨")",
            "손가락 펼침: \(areFingersExtended ? "충족" : "미충족")",
            "팔꿈치/전완: \(hasForearmOrElbowTracking ? "직접 추적" : "직접 추적 불가, 손 관절 기반 추정")",
            String(format: "손목 회전 각도: %.1f도", rollDegrees),
            String(format: "정규화 밝기: %.2f", normalizedBrightness),
            String(format: "Light intensity: %.2f", lightIntensity),
            "관절 인식: \(trackedJointCount)개",
            "상태: \(status)",
            "추가: \(extra)"
        ]
    }
}

@MainActor
final class RightHandLightDialController {

    typealias TargetProvider = (SIMD3<Float>) -> ModelEntity?
    typealias IntensityApplier = (ModelEntity, Float) -> Void

    private let targetProvider: TargetProvider
    private let intensityApplier: IntensityApplier

    private weak var activeTarget: ModelEntity?
    private var smoothedIntensity: Float = SphereLightComponent.defaultIntensity
    private var smoothedNormalizedBrightness: Float = SphereLightComponent.defaultIntensity / SphereLightComponent.maximumIntensity

    private let minIntensity = SphereLightComponent.minimumIntensity
    private let maxIntensity = SphereLightComponent.maximumIntensity
    private let inputSmoothingAmount: Float = 0.055
    private let intensitySmoothingAmount: Float = 0.065

    private(set) var debugState = RightHandLightDebugState()

    init(
        targetProvider: @escaping TargetProvider,
        intensityApplier: @escaping IntensityApplier
    ) {
        self.targetProvider = targetProvider
        self.intensityApplier = intensityApplier
    }

    func process(anchor: HandAnchor) {
        guard anchor.chirality == .right else {
            return
        }

        guard anchor.isTracked,
              let sample = RightHandWristRollSample(anchor: anchor) else {
            activeTarget = nil
            debugState = RightHandLightDebugState(
                status: "오른손 앵커/스켈레톤 인식 안됨",
                extra: "오른손을 Vision Pro 시야 안으로 넣어주세요."
            )
            return
        }

        guard sample.isWristTracked else {
            activeTarget = nil
            debugState = RightHandLightDebugState(
                isRightHandTracked: true,
                status: "오른손은 인식됐지만 손목 관절 인식 안됨",
                extra: "손목이 가려지지 않게 손 전체를 보여주세요."
            )
            return
        }

        let fingersExtended = sample.areAllFingersExtended
        let target = targetProvider(sample.wristPosition)
        if target !== activeTarget {
            smoothedIntensity = target?.components[SphereLightComponent.self]?.intensity
                ?? SphereLightComponent.defaultIntensity
            smoothedNormalizedBrightness = sample.normalizedBrightness
            activeTarget = target
        }

        let curvedBrightness = brightnessCurve(sample.normalizedBrightness)
        if fingersExtended {
            smoothedNormalizedBrightness += (curvedBrightness - smoothedNormalizedBrightness)
                * inputSmoothingAmount
        }

        let displayBrightness = fingersExtended ? smoothedNormalizedBrightness : curvedBrightness
        let targetIntensity = minIntensity + displayBrightness * (maxIntensity - minIntensity)
        if fingersExtended, let target {
            let nextIntensity = smoothedIntensity + ((targetIntensity - smoothedIntensity) * intensitySmoothingAmount)
            smoothedIntensity = nextIntensity
            intensityApplier(target, nextIntensity)
        }

        debugState = RightHandLightDebugState(
            isRightHandTracked: true,
            isWristTracked: sample.isWristTracked,
            areFingersExtended: fingersExtended,
            hasForearmOrElbowTracking: false,
            rollDegrees: sample.rollDegrees,
            normalizedBrightness: displayBrightness,
            lightIntensity: fingersExtended ? smoothedIntensity : targetIntensity,
            trackedJointCount: sample.joints.count,
            status: fingersExtended ? "오른손 손목 회전으로 밝기 조절 중" : "손가락 펼침 조건 미충족",
            extra: "팔꿈치 직접 관절은 HandTrackingProvider에서 제공되지 않아 손목+손바닥 관절로 전완 방향을 추정합니다."
        )
    }

    private func brightnessCurve(_ rawValue: Float) -> Float {
        let t = rawValue.clamped(to: 0...1)
        let smoother = t * t * t * (t * (t * 6 - 15) + 10)
        return (0.08 + smoother * 0.92).clamped(to: 0...1)
    }

    func cancelDial() {
        activeTarget = nil
        debugState = RightHandLightDebugState(status: "오른손 추적 해제")
    }
}

private struct RightHandWristRollSample {
    let joints: [String: SIMD3<Float>]
    let wristPosition: SIMD3<Float>
    let isWristTracked: Bool
    let areAllFingersExtended: Bool
    let rollDegrees: Float
    let normalizedBrightness: Float

    init?(anchor: HandAnchor) {
        guard let skeleton = anchor.handSkeleton else {
            return nil
        }

        var joints = Self.trackedJoints(from: skeleton, in: anchor)
        guard let wrist = joints["wrist"] else {
            return nil
        }
        if let estimate = Self.forearmEstimate(joints: joints, wrist: wrist) {
            joints["forearmEstimate"] = estimate
        }

        self.joints = joints
        self.wristPosition = wrist
        self.isWristTracked = true
        self.areAllFingersExtended = Self.areAllFingersExtended(joints: joints, wrist: wrist)

        let roll = Self.palmRoll(joints: joints, wrist: wrist)
        self.rollDegrees = roll.degrees
        self.normalizedBrightness = roll.normalized
    }

    private static func trackedJoints(
        from skeleton: HandSkeleton,
        in anchor: HandAnchor
    ) -> [String: SIMD3<Float>] {
        let jointNames: [(String, HandSkeleton.JointName)] = [
            ("wrist", .wrist),
            ("thumbKnuckle", .thumbKnuckle),
            ("thumbIntermediateBase", .thumbIntermediateBase),
            ("thumbIntermediateTip", .thumbIntermediateTip),
            ("thumbTip", .thumbTip),
            ("indexMetacarpal", .indexFingerMetacarpal),
            ("indexKnuckle", .indexFingerKnuckle),
            ("indexIntermediateBase", .indexFingerIntermediateBase),
            ("indexIntermediateTip", .indexFingerIntermediateTip),
            ("indexTip", .indexFingerTip),
            ("middleMetacarpal", .middleFingerMetacarpal),
            ("middleKnuckle", .middleFingerKnuckle),
            ("middleIntermediateBase", .middleFingerIntermediateBase),
            ("middleIntermediateTip", .middleFingerIntermediateTip),
            ("middleTip", .middleFingerTip),
            ("ringMetacarpal", .ringFingerMetacarpal),
            ("ringKnuckle", .ringFingerKnuckle),
            ("ringIntermediateBase", .ringFingerIntermediateBase),
            ("ringIntermediateTip", .ringFingerIntermediateTip),
            ("ringTip", .ringFingerTip),
            ("littleMetacarpal", .littleFingerMetacarpal),
            ("littleKnuckle", .littleFingerKnuckle),
            ("littleIntermediateBase", .littleFingerIntermediateBase),
            ("littleIntermediateTip", .littleFingerIntermediateTip),
            ("littleTip", .littleFingerTip)
        ]

        var result: [String: SIMD3<Float>] = [:]
        for (key, name) in jointNames {
            let joint = skeleton.joint(name)
            guard joint.isTracked else {
                continue
            }
            result[key] = worldPosition(for: joint, in: anchor)
        }
        return result
    }

    private static func areAllFingersExtended(joints: [String: SIMD3<Float>], wrist: SIMD3<Float>) -> Bool {
        let longFingerKeys = [
            ("indexKnuckle", "indexIntermediateTip", "indexTip"),
            ("middleKnuckle", "middleIntermediateTip", "middleTip"),
            ("ringKnuckle", "ringIntermediateTip", "ringTip"),
            ("littleKnuckle", "littleIntermediateTip", "littleTip")
        ]

        let longFingersOpen = longFingerKeys.allSatisfy { knuckleKey, middleKey, tipKey in
            guard let knuckle = joints[knuckleKey],
                  let middle = joints[middleKey],
                  let tip = joints[tipKey] else {
                return false
            }

            return simd_distance(tip, wrist) > simd_distance(middle, wrist) + 0.012 &&
                simd_distance(tip, wrist) > simd_distance(knuckle, wrist) + 0.035
        }

        guard let thumbKnuckle = joints["thumbKnuckle"],
              let thumbTip = joints["thumbTip"] else {
            return false
        }

        let thumbOpen = simd_distance(thumbTip, wrist) > simd_distance(thumbKnuckle, wrist) + 0.035
        return longFingersOpen && thumbOpen
    }

    private static func palmRoll(
        joints: [String: SIMD3<Float>],
        wrist: SIMD3<Float>
    ) -> (degrees: Float, normalized: Float) {
        guard let index = joints["indexMetacarpal"] ?? joints["indexKnuckle"],
              let little = joints["littleMetacarpal"] ?? joints["littleKnuckle"] else {
            return (0, SphereLightComponent.defaultIntensity)
        }

        let acrossPalm = simd_normalize(index - little)
        let towardFingers = simd_normalize(((index + little) * 0.5) - wrist)
        let palmNormal = simd_normalize(simd_cross(acrossPalm, towardFingers))
        let upAmount = simd_dot(palmNormal, SIMD3<Float>(0, 1, 0)).clamped(to: -1...1)

        // Palm normal down(-1) to up(+1) maps to dark...bright across the full wrist flip.
        let normalized = ((upAmount + 1) * 0.5).clamped(to: 0...1)
        let degrees = asin(upAmount) * 180 / .pi
        return (degrees, normalized)
    }

    private static func forearmEstimate(
        joints: [String: SIMD3<Float>],
        wrist: SIMD3<Float>
    ) -> SIMD3<Float>? {
        guard let middle = joints["middleMetacarpal"] ?? joints["middleKnuckle"] else {
            return nil
        }

        let towardFingers = middle - wrist
        guard simd_length(towardFingers) > 0.001 else {
            return nil
        }

        return wrist - simd_normalize(towardFingers) * 0.18
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

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
