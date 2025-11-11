//
//  DataToggleButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/8/25.
//

import SwiftUI

struct DataToggleButton: View {
    @Environment(InsightStore.self) private var insightStore
    @AppStorage(.UserDefault.hasGrantedSleepReadPermission) private var hasSleepPermissions: Bool = false
    @AppStorage(.UserDefault.sleepDataInsights) private var sleepDataEnabled: Bool = true

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
                                systemImage: sleepDataEnabled ? "bed.double.fill" : "moon"
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
