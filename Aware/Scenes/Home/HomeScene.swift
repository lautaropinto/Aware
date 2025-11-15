//
//  HomeScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI
import OSLog

private var logger = Logger(subsystem: "Aware", category: "HomeScene")

struct HomeScene: View {
    @State private var isSettingsPresented = false
    
    @Namespace private var settingsTransition
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    StopWatch()
                        .rateAppPrompt()
                        .padding(.horizontal)
                    
                    QuickStartSection()
                }
                .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
//            .applyBackgroundGradient()
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton(isSettingsPresented: self.$isSettingsPresented, transition: settingsTransition)
                }
                .matchedTransitionSource(id: "settings", in: settingsTransition)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsButton.SettingsScene()
                .navigationTransition(.zoom(sourceID: "settings", in: settingsTransition))
        }
    }
}

#Preview {
    HomeScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
