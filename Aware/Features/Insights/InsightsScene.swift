//
//  InsightsScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI
import SwiftData
import AwareData

struct InsightsScene: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Storage.self) private var storage
    @State private var insightStore = InsightStore()
    
    var body: some View {
        @Bindable var store = insightStore
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    TimeFramePicker(
                        selectedDayDate: $store.selectedDate,
                        showUntrackedTime: $store.showUntrackedTime
                    )
                    .rounded()

                    if insightStore.hasData {
                        PieChartView(
                            data: insightStore.insightData,
                            totalTime: insightStore.totalTimeForPeriod
                        )
                    } else {
                        InsightsEmptyState()
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DataToggleButton()
                }
            }
            .applyBackgroundGradient()
        }
        .onAppear {
            insightStore.configure(storage: storage, healthKitManager: HealthKitManager.shared)
            insightStore.refreshData()
            Tracker.signal("insights.viewed", params: [
                "sleep_data": insightStore.sleepDataEnabled.description,
                "workout_data": insightStore.workoutDataEnabled.description,
            ])
        }
        .onChange(of: store.selectedDate) { _, newDate in
            insightStore.updateDate(to: newDate)
        }
        .onChange(of: store.showUntrackedTime) { _, newValue in
            insightStore.updateShowUntrackedTime(to: newValue)
        }
        .environment(insightStore)
    }
}

#Preview {
    InsightsScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
