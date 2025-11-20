//
//  TabScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import SwiftUI
import AwareUI

struct TabScene: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appConfig) private var appConfig
    @State private var showHealthKitPermissionSheet = false
    @State private var storage = Storage.shared
    @State private var awarenessSession = AwarenessSession.shared
    @State private var healthKitManager = HealthKitManager.shared
    @State private var liveActivityManager = LiveActivityManager.shared
    
    var body: some View {
        TabView {
            HomeScene()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .setUpIntentNotificationListener()
                .environment(awarenessSession)

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
        .environment(storage)
        .background(Color.background)
        .accentColor(.primary)
        .sheet(isPresented: $showHealthKitPermissionSheet, onDismiss: {
            UserDefaults.standard.set(true, forKey: .UserDefault.healthKitSleepPermissionsRequested)
        }) {
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
        .onAppear {
            storage.configure(context: self.modelContext)
            awarenessSession.configure(
                storage: storage,
                liveActivityManager: liveActivityManager,
                appConfig: appConfig
            )
            updateBackgroundColor()
            checkHealthKitPermissions()
        }
        .onChange(of: awarenessSession.activeTimer) { _, _ in
            updateBackgroundColor()
        }
    }
    
    private func updateBackgroundColor() {
        if let timer = awarenessSession.activeTimer {
            // Use the timer's color if there's an active timer
            appConfig.updateColor(timer.swiftUIColor)
        } else {
            // Use accent color if no timer is active
            appConfig.updateColor(.accent)
        }
    }

    private func checkHealthKitPermissions() {
        let hasRequestedBefore = UserDefaults.standard.bool(forKey: .UserDefault.healthKitSleepPermissionsRequested)

        guard !hasRequestedBefore else { return }

        // Show permission sheet after a brief delay to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showHealthKitPermissionSheet = true
        }
    }

    private func requestHealthKitPermissions() {
        healthKitManager.requestSleepPermissions()
    }
}

#Preview {
    TabScene()
}
