//
//  HistoryList.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/16/25.
//

import SwiftUI
import AwareData
import HealthKit

struct HistoryList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(History.self) private var history
    @Environment(Storage.self) private var storage

    private func sortedTimers(for date: Date) -> [any TimelineEntry] {
        history.sortedTimers(for: date)
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
        !history.sortedDates.isEmpty
    }
    
    var body: some View {
        List {
            ForEach(history.sortedDates, id: \.self) { date in
                Section {
                    ForEach(sortedTimers(for: date), id: \.id) { entry in
                        TimerRowView(for: entry)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .transition(.scale.combined(with: .opacity))
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
    private func TimerRowView(for entry: any TimelineEntry) -> some View {
        switch entry.type {
        case .timekeeper:
            RecentTimerRow(entry: entry)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if let timekeeper = entry as? Timekeeper {
                        Button("Delete", role: .destructive) {
                            deleteTimer(timekeeper)
                        }
                    }
                }
        case .sleep:
            SleepRow(entry: entry)
        case .workout:
            WorkoutRow(entry: entry)
        }
    }
    
    private func deleteTimer(_ timer: Timekeeper) {
        withAnimation {
            modelContext.delete(timer)
            try? modelContext.save()
            storage.fetchTimers()
        }
    }
}

#Preview {
    HistoryList()
}
