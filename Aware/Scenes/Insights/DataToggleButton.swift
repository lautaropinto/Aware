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
    @AppStorage(.UserDefault.hasGrantedWorkoutReadPermission) private var hasWorkoutPermissions: Bool = false
    @AppStorage(.UserDefault.sleepDataInsights) private var sleepDataEnabled: Bool = true
    @AppStorage(.UserDefault.workoutDataInsights) private var workoutDataEnabled: Bool = true

    var body: some View {
        Group {
            if hasSleepPermissions || hasWorkoutPermissions {
                Menu {
                    Section("Health Data") {
                        if hasSleepPermissions {
                            Button(action: {
                                toggleSleepData()
                            }) {
                                Label(
                                    sleepDataEnabled ? "Hide Sleep Data" : "Show Sleep Data",
                                    systemImage: sleepDataEnabled ? "bed.double.fill" : "moon"
                                )
                            }
                        }

                        if hasWorkoutPermissions {
                            Button(action: {
                                toggleWorkoutData()
                            }) {
                                Label(
                                    workoutDataEnabled ? "Hide Workout Data" : "Show Workout Data",
                                    systemImage: workoutDataEnabled ? "figure.mixed.cardio" : "dumbbell"
                                )
                            }
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

    private func toggleWorkoutData() {
        workoutDataEnabled.toggle()
        UserDefaults.standard.set(workoutDataEnabled, forKey: .UserDefault.workoutDataInsights)
        insightStore.updateWorkoutDataVisibility(to: workoutDataEnabled)
    }
}

#Preview {
    DataToggleButton()
        .environment(InsightStore())
}
