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
                VStack {
                    List {
                        EmailSenderSection()
                        RateAppSection()
                        AboutListSection()
                    }
                    .navigationTitleWithCloseButton("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .scrollContentBackground(.hidden)
                    .background(
                        Color.accent.mix(with: .background, by: 0.8)
                            .edgesIgnoringSafeArea(.all)
                    )
                    .background(
                        VStack {
                            Spacer()
                            Text("Aware \(Bundle.versionNumber)")
                            Text("Built slowly. Intentionally.")
                                .monospaced()
                        }
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.72))
                    )
                }
            }
        }
    }
}

#Preview {
    SettingsButton.SettingsScene()
}
