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

    private var anchorUpdatesTask: Task<Void, Never>?
    private var lightDialController: LightDialController?

    func connectLightDialController(_ controller: LightDialController) {
        lightDialController = controller
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
            lightDialController?.process(anchor: update.anchor)

        case .removed:
            lightDialController?.cancelDial()
        }
    }
}
