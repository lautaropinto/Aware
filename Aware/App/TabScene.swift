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
                appConfig: CrossConfig(backgroundColor: Color.accent) // This should come from environment
            )
            checkHealthKitPermissions()
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
