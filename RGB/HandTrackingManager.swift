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
    @Published private(set) var debugStatus = "Hand tracking diagnostics idle."

    private var anchorUpdatesTask: Task<Void, Never>?
    private var lightDialController: LightDialController?
    private var lastAnchorDebugLogTime: TimeInterval = 0

    func connectLightDialController(_ controller: LightDialController) {
        lightDialController = controller
        controller.diagnosticsHandler = { [weak self] message in
            self?.publishDebugStatus(message)
        }
    }

    func start() async {
        guard !isRunning, anchorUpdatesTask == nil else {
            return
        }

        // 현재 실행 환경이 핸드 트래킹을 지원하는지 확인
        guard HandTrackingProvider.isSupported else {
            print("Hand tracking is not supported in this environment.")
            return
        }

        do {
            let authorizationResults = await session.requestAuthorization(
                for: [.handTracking]
            )

            guard authorizationResults[.handTracking] == .allowed else {
                print("Hand tracking authorization was not granted.")
                return
            }

            // Vision Pro의 핸드 트래킹 시작
            try await session.run([handTrackingProvider])

            isRunning = true
            startAnchorUpdates()
            print("Hand tracking started.")
        } catch {
            isRunning = false
            print("Failed to start hand tracking: \(error)")
        }
    }

    func stop() {
        anchorUpdatesTask?.cancel()
        anchorUpdatesTask = nil
        lightDialController?.cancelDial()
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
        switch update.event {
        case .added, .updated:
            logAnchorDiagnostics(update.anchor)
            lightDialController?.process(anchor: update.anchor)

        case .removed:
            publishDebugStatus("HandAnchor removed. light dial canceled.")
            lightDialController?.cancelDial()
        }
    }

    private func logAnchorDiagnostics(_ anchor: HandAnchor) {
        let now = ProcessInfo.processInfo.systemUptime

        guard now - lastAnchorDebugLogTime >= 0.5 else {
            return
        }

        lastAnchorDebugLogTime = now

        let hasSkeleton = anchor.handSkeleton != nil
        publishDebugStatus(
            "HandAnchor update chirality=\(anchor.chirality) " +
            "isTracked=\(anchor.isTracked) handSkeleton=\(hasSkeleton)"
        )
    }

    private func publishDebugStatus(_ message: String) {
        debugStatus = message
        print("[HandLightDebug] \(message)")
    }
}
