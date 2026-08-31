//
//  ContentView.swift
//  handtracking
//
//  Created by Seojin Lee on 8/26/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fingers.spread")
                .font(.system(size: 64))
                .foregroundStyle(.cyan)

            Text("Hand Skeleton")
                .font(.largeTitle)

            Text("왼손은 청록색, 오른손은 자홍색으로 표시됩니다.")
                .foregroundStyle(.secondary)

            ToggleImmersiveSpaceButton()
        }
        .padding(40)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
