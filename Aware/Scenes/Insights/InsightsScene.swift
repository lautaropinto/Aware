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
    @State private var insightStore = InsightStore()
    
    var body: some View {
        @Bindable var store = insightStore
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    TimeFramePicker(
                        selectedTimeFrame: $store.selectedTimeFrame,
                        selectedDayDate: $store.selectedDayDate,
                        selectedWeekDate: $store.selectedWeekDate,
                        selectedMonthDate: $store.selectedMonthDate,
                        selectedYearDate: $store.selectedYearDate,
                        showUntrackedTime: $store.showUntrackedTime
                    )
                    
                    PieChartView(
                        data: insightStore.getInsightData(),
                        totalTime: insightStore.totalTimeForPeriod
                    )
                }
                .padding()
            }
            .applyBackgroundGradient()
            .navigationTitle("Insights")
        }
        .onAppear {
            insightStore.setModelContext(modelContext)
            insightStore.updateTimeFrame(to: store.selectedTimeFrame)
        }
        .onChange(of: store.selectedTimeFrame) { _, newTimeFrame in
            insightStore.updateTimeFrame(to: newTimeFrame)
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
