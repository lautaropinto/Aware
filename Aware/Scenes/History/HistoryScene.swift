//
//  HistoryScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData

struct HistoryScene: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tags: [Tag]
    @Query(
        sort: [SortDescriptor(\Timekeeper.creationDate, order: .reverse)]
    ) private var allTimers: [Timekeeper]
    
    @State private var selectedTag: Tag?
    
    // Filter timers based on tag selection
    private var filteredTimers: [Timekeeper] {
        guard let selectedTag = selectedTag else { return allTimers }
        return allTimers.filter { $0.mainTag?.id == selectedTag.id }
    }
    
    // Group entries by day
    private var groupedEntries: [Date: [Timekeeper]] {
        let grouped = Dictionary(grouping: filteredTimers) { entry in
            Calendar.current.startOfDay(for: entry.creationDate)
        }
        
        // Sort entries within each group once during grouping
        return grouped.mapValues { entries in
            entries.sorted(by: { $0.creationDate > $1.creationDate })
        }
    }
    
    private var sortedDates: [Date] {
        groupedEntries.keys.sorted(by: >)
    }
    
    private func sortedTimers(for date: Date) -> [Timekeeper] {
        groupedEntries[date] ?? []
    }
    
    private func totalElapsedTime(for date: Date) -> String {
        let timers = sortedTimers(for: date)
        let totalTime = timers.reduce(0) { partialResult, timer in
            partialResult + timer.totalElapsedSeconds
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
                    ForEach(sortedTimers(for: date)) { timekeeper in
                        timerRowView(for: timekeeper)
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
    
    private func timerRowView(for timekeeper: Timekeeper) -> some View {
        RecentTimerRow(timekeeper: timekeeper)
            .transition(.scale.combined(with: .opacity))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Delete", role: .destructive) {
                    deleteTimer(timekeeper)
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
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
