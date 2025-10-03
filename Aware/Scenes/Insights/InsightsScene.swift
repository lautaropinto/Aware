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

    @State private var selectedTimeFrame: TimeFrame = .currentWeek
    @State private var selectedDayDate: Date = Date().startOfDay
    @State private var selectedWeekDate: Date = Date().startOfWeek
    @State private var selectedMonthDate: Date = Date().startOfMonth
    @State private var selectedYearDate: Date = Date().startOfYear
    @State private var showUntrackedTime: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
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
            insightStore.updateTimeFrame(to: selectedTimeFrame)
        }
        .onChange(of: selectedTimeFrame) { _, newTimeFrame in
            insightStore.updateTimeFrame(to: newTimeFrame)
        }
        .onChange(of: showUntrackedTime) { _, newValue in
            insightStore.updateShowUntrackedTime(to: newValue)
        }
    }

    private var headerSection: some View {
        TimeFramePicker(
            selectedTimeFrame: $selectedTimeFrame,
            selectedDayDate: $selectedDayDate,
            selectedWeekDate: $selectedWeekDate,
            selectedMonthDate: $selectedMonthDate,
            selectedYearDate: $selectedYearDate,
            showUntrackedTime: $showUntrackedTime
        )
    }
}

#Preview {
    InsightsScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
