//
//  SettingsScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

extension SettingsButton {
    struct SettingsScene: View {
        var body: some View {
            NavigationStack {
                List {
                    AboutListSection()
                }
                .navigationTitleWithCloseButton("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .scrollContentBackground(.hidden)
                .applyBackgroundGradient()
            }
        }
    }
}

#Preview {
    SettingsButton.SettingsScene()
}
