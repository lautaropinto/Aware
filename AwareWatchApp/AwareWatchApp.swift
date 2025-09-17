//
//  AwareWatchApp.swift
//  AwareWatch Watch App
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import AwareData
import AwareUI

@main
struct AwareWatch_Watch_AppApp: App {
    @AppStorage("watchOS-onboarding-ftu-completed") private var isOnboardingComplete: Bool = false
    @State private var isShowingFTU = false
    @State private var appConfig = CrossConfig(backgroundColor: Color.accentColor)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .swiftDataSetUp()
                .onAppear {
                    if !isOnboardingComplete {
                        isShowingFTU = true
                    }
                }
                .sheet(isPresented: $isShowingFTU, onDismiss: {
                    isOnboardingComplete = true
                }) {
                    Onboarding()
                }
                .environment(\.appConfig, appConfig)
        }
    }
}
