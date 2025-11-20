//
//  ContentView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("aware-onboarding-ftu-completed") var onboardingCompleted = false
    
    var body: some View {
        VStack {
            if onboardingCompleted {
                TabScene()
                    .opacity(onboardingCompleted ? 1.0 : 0)
            } else {
                OnboardingFlow()
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

#Preview {
    ContentView()
}
