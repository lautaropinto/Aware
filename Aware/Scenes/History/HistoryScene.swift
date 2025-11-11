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
    var image: String { "moon.fill" }
    var type: TimelineEntryType { .sleep }
}

struct HistoryScene: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(.UserDefault.hasGrantedSleepReadPermission) var hasSleepPermission: Bool = false
    
    @Query private var tags: [Tag]
    @Query(
        sort: [SortDescriptor(\Timekeeper.creationDate, order: .reverse)]
    ) private var allTimers: [Timekeeper]

    @State private var selectedTag: Tag?
    @State private var sleepData: [HKCategorySample] = []

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

    // Combine timers and aggregated sleep data
    private var combinedEntries: [any TimelineEntry] {
        var entries: [any TimelineEntry] = allTimers
        entries.append(contentsOf: aggregatedSleepEntries)
        return entries
    }

    // Filter timers based on tag selection (sleep data has no tags, so always included)
    private var filteredTimers: [any TimelineEntry] {
        guard let selectedTag = selectedTag else { return combinedEntries }
        let filteredTimers = allTimers.filter { $0.mainTag?.id == selectedTag.id }
        var result: [any TimelineEntry] = filteredTimers
        result.append(contentsOf: aggregatedSleepEntries)
        return result
    }
    
    // Group entries by day
    private var groupedEntries: [Date: [any TimelineEntry]] {
        let grouped = Dictionary(grouping: filteredTimers) { entry in
            Calendar.current.startOfDay(for: entry.creationDate)
        }

        // Sort entries within each group
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
    
    private func totalElapsedTime(for date: Date) -> String {
        let timers = sortedTimers(for: date)
        let totalTime = timers.reduce(0) { partialResult, timer in
            partialResult + timer.duration
        }

        return TimeInterval(floatLiteral: totalTime).formattedElapsedTime
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
                    ManualEntryButton()
                }
            }
            .applyBackgroundGradient()
        }
        .onAppear {
            loadSleepData()
        }
        .onChange(of: selectedTag) { _, _ in
            loadSleepData()
        }
    }
    
    // MARK: - Computed Views

    private var tagFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFilterButton
                tagFilterButtons
            }
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
                    }
                } header: {
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(date.smartFormattedDate)")
                        Text("Total time: \(totalElapsedTime(for: date))")
                            .font(.caption2.italic())
                            .opacity(0.8)
                            .contentTransition(.numericText())
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
                // Future: WorkoutRow(entry: entry)
                RecentTimerRow(entry: entry)
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

    private func loadSleepData() {
        guard self.hasSleepPermission else {
            logger.error("Has no permission. Will not load sleep data.")
            return
        }

        logger.debug("Load sleep data")
        
        Task {
            do {
                // Fetch sleep data for the last 30 days
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
                let dateInterval = DateInterval(start: startDate, end: endDate)

                let fetchedSleepData = try await HealthStore.shared.fetchSleepData(for: dateInterval)

                await MainActor.run {
                    logger.debug("Sleep data. \(fetchedSleepData.count)")
                    self.sleepData = fetchedSleepData
                }
            } catch(let error) {
                logger.error("Error loading sleep data. Error: \(error)")
                await MainActor.run {
                    self.sleepData = []
                }
            }
        }
    }
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
