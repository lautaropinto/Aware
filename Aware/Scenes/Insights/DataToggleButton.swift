//
//  DataToggleButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/8/25.
//

import SwiftUI

struct DataToggleButton: View {
    @Environment(InsightStore.self) private var insightStore
    @State private var sleepDataEnabled: Bool = UserDefaults.standard.bool(forKey: .UserDefault.sleepDataInsights)
    @State private var hasSleepPermissions: Bool = false

    init() {
        // Set default to true if not previously set
        if !UserDefaults.standard.exists(key: .UserDefault.sleepDataInsights) {
            UserDefaults.standard.set(true, forKey: .UserDefault.sleepDataInsights)
            _sleepDataEnabled = State(initialValue: true)
        }
    }

    var body: some View {
        Group {
            if hasSleepPermissions {
                Menu {
                    Section("Health Data") {
                        Button(action: {
                            toggleSleepData()
                        }) {
                            Label(
                                sleepDataEnabled ? "Hide Sleep Data" : "Show Sleep Data",
                                systemImage: sleepDataEnabled ? "moon.fill" : "moon"
                            )
                        }
                    }
                } label: {
                    Image(systemName: "chart.pie")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            sleepDataEnabled = UserDefaults.standard.bool(forKey: .UserDefault.sleepDataInsights)
            hasSleepPermissions = HealthStore.shared.hasSleepPermissions()
        }
    }

    private func toggleSleepData() {
        sleepDataEnabled.toggle()
        UserDefaults.standard.set(sleepDataEnabled, forKey: .UserDefault.sleepDataInsights)
        insightStore.updateSleepDataVisibility(to: sleepDataEnabled)
    }
}

#Preview {
    DataToggleButton()
        .environment(InsightStore())
}