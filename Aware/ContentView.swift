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

    @Environment(\.modelContext) private var modelContext

    @State private var slowlyAppear = false
    @State private var activityStore = ActivityStore()
    @State private var showHealthKitPermissionSheet = false
    
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
                checkHealthKitPermissions()
            }
        }
        .onAppear {
            slowlyAppear = onboardingCompleted
            activityStore.modelContext = self.modelContext
            if onboardingCompleted {
                checkHealthKitPermissions()
            }
        }
        .sheet(isPresented: $showHealthKitPermissionSheet) {
            HealthKitPermissionSheet(
                isPresented: $showHealthKitPermissionSheet,
                onSetupNow: {
                    showHealthKitPermissionSheet = false
                    requestHealthKitPermissions()   
                },
                onSetupLater: {
                    showHealthKitPermissionSheet = false
                    UserDefaults.standard.set(true, forKey: .UserDefault.healthKitSleepPermissionsRequested)
                }
            )
        }
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
                .setUpIntentNotificationListener()
                .environment(activityStore)

            HistoryScene()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)

            InsightsScene()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Insights")
                }
                .tag(2)
        }
        .background(Color.background)
        .accentColor(.primary)
    }

    // MARK: - HealthKit Permission Management

    private func checkHealthKitPermissions() {
        let hasRequestedBefore = UserDefaults.standard.bool(forKey: .UserDefault.healthKitSleepPermissionsRequested)

        guard !hasRequestedBefore else { return }

        // Show permission sheet after a brief delay to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showHealthKitPermissionSheet = true
        }
    }

    private func requestHealthKitPermissions() {
        HealthStore.shared.requestSleepPermissions()
    }
}

#Preview {
    ContentView()
}
