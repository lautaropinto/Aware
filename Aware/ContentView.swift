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
    
    @State private var slowlyAppear = false
    
    var body: some View {
        VStack {
            if onboardingCompleted {
                TabScene()
                    .opacity(slowlyAppear ? 1.0 : 0)
            } else {
                OnboardingFlow()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onChange(of: onboardingCompleted) { _, newValue in
            if newValue {
                withAnimation(.spring(duration: 1.5)) { slowlyAppear = true }
            }
        }
        .onAppear { slowlyAppear = onboardingCompleted }
    }
    
    @ViewBuilder
    func TabScene() -> some View {
        TabView {
            HomeScene()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            HistoryScene()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
        }
        .background(Color.background)
        .accentColor(.primary)
    }
}

#Preview {
    ContentView()
}
