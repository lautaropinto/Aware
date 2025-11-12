//
//  HistoryScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import HealthKit
import OSLog

private var logger = Logger(subsystem: "HistoryScene", category: "Scene")


// Aggregated sleep entry for a single day
private struct DailySleepEntry: TimelineEntry {
    let id = UUID()
    let date: Date
    let totalDuration: TimeInterval
    let startTime: Date?
    let endTime: Date?

    var name: String { "Sleep" }
    var creationDate: Date { date }
    var duration: TimeInterval { totalDuration }
    var swiftUIColor: Color {
        if let color = Color(hex: .sleepColor) {
            return color
        }
        return .blue
    }
    var image: String { "bed.double.fill" }
    var type: TimelineEntryType { .sleep }
}


struct HistoryScene: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(.UserDefault.hasGrantedSleepReadPermission) var hasSleepPermission: Bool = false
    @AppStorage(.UserDefault.hasGrantedWorkoutReadPermission) var hasWorkoutPermission: Bool = false

    @Query private var tags: [Tag]
    @Query(
        sort: [SortDescriptor(\Timekeeper.creationDate, order: .reverse)]
    ) private var allTimers: [Timekeeper]

    @State private var selectedTag: Tag?
    @State private var sleepData: [HKCategorySample] = []
    @State private var workoutData: [HKWorkout] = []
    @State private var isLoadingSleepData = false
    @State private var isLoadingWorkoutData = false
    @State private var hasLoadedHealthData = false

    // Aggregate sleep data by day into single entries
    private var aggregatedSleepEntries: [DailySleepEntry] {
        let groupedSleep = Dictionary(grouping: sleepData) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }

        return groupedSleep.compactMap { (date, samples) -> DailySleepEntry? in
            guard !samples.isEmpty else { return nil }

            let totalDuration = samples.reduce(0) { $0 + $1.duration }
            let earliestStart = samples.min(by: { $0.startDate < $1.startDate })?.startDate
            let latestEnd = samples.max(by: { $0.endDate < $1.endDate })?.endDate

            return DailySleepEntry(
                date: date,
                totalDuration: totalDuration,
                startTime: earliestStart,
                endTime: latestEnd
            )
        }
    }


    // Combine timers, aggregated sleep data, and individual workout data
    private var combinedEntries: [any TimelineEntry] {
        var entries: [any TimelineEntry] = allTimers
        entries.append(contentsOf: aggregatedSleepEntries)
        entries.append(contentsOf: workoutData)
        return entries
    }

    // Filter timers based on tag selection
    private var filteredTimers: [any TimelineEntry] {
        guard let selectedTag = selectedTag else { return combinedEntries }
        // When filtering by tag, only show Timekeeper entries with that tag (exclude HealthKit data)
        return allTimers.filter { $0.mainTag?.id == selectedTag.id }
    }
    
    // Group entries by day
    private var groupedEntries: [Date: [any TimelineEntry]] {
        let grouped = Dictionary(grouping: filteredTimers) { entry in
            Calendar.current.startOfDay(for: entry.creationDate)
        }

        // Sort entries
        return grouped.mapValues { entries in
            entries.sorted(by: { $0.creationDate > $1.creationDate })
        }
    }
    
    private var sortedDates: [Date] {
        groupedEntries.keys.sorted(by: >)
    }
    
    private func sortedTimers(for date: Date) -> [any TimelineEntry] {
        groupedEntries[date] ?? []
    }
    

    private func totalIntentionalTimeInSeconds(for date: Date) -> TimeInterval {
        let timers = sortedTimers(for: date)
        return timers.reduce(0) { partialResult, timer in
            // Only count Timekeeper entries (intentional time tracking)
            if timer is Timekeeper {
                return partialResult + timer.duration
            }
            return partialResult
        }
    }

    private func totalIntentionalTime(for date: Date) -> String {
        let totalTime = totalIntentionalTimeInSeconds(for: date)
        return TimeInterval(floatLiteral: totalTime).compactFormattedTime
    }
    
    private var hasFilteredResults: Bool {
        !filteredTimers.isEmpty
    }
    
    private var isTagFilterActive: Bool {
        selectedTag != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tag Filter Section
                if !tags.isEmpty {
                    tagFilterSection
                }
                
                // Timer List
                timerListSection
            }   
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if isLoadingSleepData || isLoadingWorkoutData {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        ManualEntryButton()
                    }
                }
            }
            .applyBackgroundGradient()
        }
        .onAppear {
            loadHealthDataIfNeeded()
        }
    }
    
    // MARK: - Computed Views

    private var tagFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFilterButton
                tagFilterButtons
            }
            .rounded()
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
    
    private var allFilterButton: some View {
        FilterButton(
            text: "All",
            isSelected: !isTagFilterActive,
            color: .primary,
            onTap: selectAllFilter
        )
    }
    
    private var tagFilterButtons: some View {
        ForEach(tags, id: \.id) { tag in
            TagFilterButton(
                tag: tag,
                isSelected: selectedTag?.id == tag.id,
                onTap: { selectTagFilter(tag) }
            )
        }
    }
    
    private var timerListSection: some View {
        Group {
            if hasFilteredResults {
                timerList
            } else {
                EmptyHistoryView(hasSearch: isTagFilterActive)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filteredTimers.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTag?.id)
    }
    
    private var timerList: some View {
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section {
                    ForEach(sortedTimers(for: date), id: \.id) { entry in
                        timerRowView(for: entry)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } header: {
                    VStack(alignment: .leading) {
                        Text("\(date.smartFormattedDate)")
                            .rounded()
                        if totalIntentionalTimeInSeconds(for: date) > .halfHour {
                            Text("\(totalIntentionalTime(for: date)) spent with intention")
                                .font(.caption2.italic())
                                .opacity(0.8)
                                .contentTransition(.numericText())
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func timerRowView(for entry: any TimelineEntry) -> some View {
        Group {
            switch entry.type {
            case .timekeeper:
                RecentTimerRow(entry: entry)
            case .sleep:
                SleepRow(entry: entry)
            case .workout:
                WorkoutRow(entry: entry)
            }
        }
        .transition(.scale.combined(with: .opacity))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Only allow deletion of Timekeeper entries
            if let timekeeper = entry as? Timekeeper {
                Button("Delete", role: .destructive) {
                    deleteTimer(timekeeper)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectAllFilter() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTag = nil
        }
    }
    
    private func selectTagFilter(_ tag: Tag) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTag = selectedTag?.id == tag.id ? nil : tag
        }
    }
    
    private func deleteTimer(_ timer: Timekeeper) {
        withAnimation {
            modelContext.delete(timer)
            try? modelContext.save()
        }
    }

    // MARK: - Sleep Data Management

    private func firstTimekeeperDate() -> Date? {
        return allTimers.min(by: { $0.creationDate < $1.creationDate })?.creationDate
    }

    // MARK: - Optimized Data Loading

    private func loadHealthDataIfNeeded() {
        guard !hasLoadedHealthData else { return }
        hasLoadedHealthData = true

        Task {
            await withTaskGroup(of: Void.self) { group in
                // Load sleep data in background
                group.addTask {
                    await self.loadSleepData()
                }

                // Load workout data in background
                group.addTask {
                    await self.loadWorkoutData()
                }
            }
        }
    }

    @MainActor
    private func loadSleepData() async {
        guard hasSleepPermission && !isLoadingSleepData else { return }

        // Don't load sleep data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load sleep data.")
            sleepData = []
            return
        }

        isLoadingSleepData = true

        do {
            let endDate = Date()
            let dateInterval = DateInterval(start: firstDate, end: endDate)

            let fetchedSleepData = try await HealthStore.shared.fetchSleepData(for: dateInterval)

            logger.debug("Sleep data. \(fetchedSleepData.count)")
            self.sleepData = fetchedSleepData
        } catch {
            logger.error("Error loading sleep data. Error: \(error)")
            self.sleepData = []
        }

        isLoadingSleepData = false
    }

    @MainActor
    private func loadWorkoutData() async {
        guard hasWorkoutPermission && !isLoadingWorkoutData else { return }

        // Don't load workout data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load workout data.")
            workoutData = []
            return
        }

        isLoadingWorkoutData = true

        do {
            let endDate = Date()
            let dateInterval = DateInterval(start: firstDate, end: endDate)

            let fetchedWorkoutData = try await HealthStore.shared.fetchWorkoutData(for: dateInterval)

            logger.debug("Workout data. \(fetchedWorkoutData.count)")
            self.workoutData = fetchedWorkoutData
        } catch {
            logger.error("Error loading workout data. Error: \(error)")
            self.workoutData = []
        }

        isLoadingWorkoutData = false
    }
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
