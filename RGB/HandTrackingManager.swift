//
//  HandTrackingManager.swift
//  RGB
//

import ARKit
import SwiftUI
import Combine

@MainActor
final class HandTrackingManager: ObservableObject {

    // Vision Pro의 ARKit 기능을 실행하는 세션
    private let session = ARKitSession()

    // 양손의 위치와 관절 움직임을 전달하는 기능
    let handTrackingProvider = HandTrackingProvider()

    @Published private(set) var isRunning = false
    @Published private(set) var debugLines = RightHandLightDebugState().lines

    private var anchorUpdatesTask: Task<Void, Never>?
    private var lightDialController: RightHandLightDialController?

    func connectLightDialController(_ controller: RightHandLightDialController) {
        lightDialController = controller
        debugLines = controller.debugState.lines
    }

    func start() async {
        guard !isRunning, anchorUpdatesTask == nil else {
            return
        }

        // 현재 실행 환경이 핸드 트래킹을 지원하는지 확인
        guard HandTrackingProvider.isSupported else {
            debugLines = RightHandLightDebugState(
                status: "이 환경에서는 손 추적을 사용할 수 없습니다.",
                extra: "Simulator라면 실제 오른손 추적이 제한될 수 있습니다."
            ).lines
            return
        }

        do {
            let authorizationResults = await session.requestAuthorization(
                for: [.handTracking]
            )

            guard authorizationResults[.handTracking] == .allowed else {
                debugLines = RightHandLightDebugState(
                    status: "손 추적 권한이 허용되지 않았습니다.",
                    extra: "Settings에서 Hand Tracking 권한을 확인하세요."
                ).lines
                return
            }

            // Vision Pro의 핸드 트래킹 시작
            try await session.run([handTrackingProvider])

            isRunning = true
            startAnchorUpdates()
            debugLines = RightHandLightDebugState(
                status: "손 추적 세션 시작",
                extra: "오른손을 펼치고 손목을 천천히 뒤집어보세요."
            ).lines
        } catch {
            isRunning = false
            debugLines = RightHandLightDebugState(
                status: "손 추적 세션 시작 실패",
                extra: error.localizedDescription
            ).lines
        }
    }

    func stop() {
        anchorUpdatesTask?.cancel()
        anchorUpdatesTask = nil
        lightDialController?.cancelDial()
        debugLines = lightDialController?.debugState.lines ?? RightHandLightDebugState(status: "손 추적 정지").lines
        session.stop()
        isRunning = false
    }

    private func startAnchorUpdates() {
        let updates = handTrackingProvider.anchorUpdates

        anchorUpdatesTask = Task { [weak self] in
            for await update in updates {
                await MainActor.run {
                    self?.handle(update)
                }
            }
        }
    }

    private func handle(_ update: AnchorUpdate<HandAnchor>) {
        guard update.anchor.chirality == .right else {
            return
        }

        switch update.event {
        case .added, .updated:
            lightDialController?.process(anchor: update.anchor)
            debugLines = lightDialController?.debugState.lines ?? debugLines

        case .removed:
            lightDialController?.cancelDial()
            debugLines = lightDialController?.debugState.lines ?? RightHandLightDebugState(status: "손 추적 제거됨").lines
        }
    }
}
