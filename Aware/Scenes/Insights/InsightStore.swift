//
//  InsightStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI
import SwiftData
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "InsightStore")

struct TagInsightData: Identifiable {
    let id = UUID()
    let tag: Tag
    let totalTime: TimeInterval
    let percentage: Double
    let sessionCount: Int

    var averageTime: TimeInterval {
        guard sessionCount > 0 else { return 0 }
        return totalTime / Double(sessionCount)
    }

    var shouldShowAverage: Bool {
        return averageTime > 1800 && sessionCount > 3 // 30 minutes = 1800 seconds
    }
}

@Observable
class InsightStore {
    var currentTimeFrame: TimeFrame = .currentWeek
    // TimeFrame Picker info
    var selectedTimeFrame: TimeFrame = .currentWeek
    var selectedDayDate: Date = Date().startOfDay
    var selectedWeekDate: Date = Date().startOfWeek
    var selectedMonthDate: Date = Date().startOfMonth
    var selectedYearDate: Date = Date().startOfYear
    var showUntrackedTime: Bool = false
    

    private var modelContext: ModelContext?

    init() {
        let storedTimeFrame = UserDefaults.standard.integer(forKey: .UserDefault.selectedTimeFrame)
        switch storedTimeFrame {
        case 0: self.selectedTimeFrame = .currentDay
        case 1: self.selectedTimeFrame = .currentWeek
        case 2: self.selectedTimeFrame = .currentMonth
        case 3: self.selectedTimeFrame = .currentYear
        case 4: self.selectedTimeFrame = .allTime
        default: self.selectedTimeFrame = .daily(.now)
        }
        
        showUntrackedTime = UserDefaults.standard.bool(forKey: .UserDefault.showUntrackedTime)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func updateTimeFrame(to newFrame: TimeFrame) {
        currentTimeFrame = newFrame
    }

    func updateShowUntrackedTime(to newValue: Bool) {
        showUntrackedTime = newValue
    }

    func getInsightData() -> [TagInsightData] {
        guard let modelContext = modelContext else { return [] }

        let descriptor: FetchDescriptor<Timekeeper>

        if let range = currentTimeFrame.dateRange {
            // Specific time range (week, month, year, daily)
            let rangeStart = range.start
            let rangeEnd = range.end

            descriptor = FetchDescriptor<Timekeeper>(
                predicate: #Predicate<Timekeeper> { timer in
                    timer.creationDate >= rangeStart && timer.creationDate < rangeEnd && timer.endTime != nil
                }
            )
        } else {
            // All time - no date filtering
            descriptor = FetchDescriptor<Timekeeper>(
                predicate: #Predicate<Timekeeper> { timer in
                    timer.endTime != nil
                }
            )
        }

        do {
            let timers = try modelContext.fetch(descriptor)
            var tagData = aggregateTimersByTag(timers)

            // Add untracked time for daily view
            if showUntrackedTime, case .daily = currentTimeFrame {
                if let untrackedData = calculateUntrackedTime(from: tagData) {
                    tagData.append(untrackedData)
                }
            }

            return tagData.sorted(by: { $0.tag.displayOrder < $1.tag.displayOrder })
        } catch {
            logger.error("Failed to fetch timers: \(error)")
            return []
        }
    }

    private func aggregateTimersByTag(_ timers: [Timekeeper]) -> [TagInsightData] {
        var tagData: [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)] = [:]

        for timer in timers {
            guard let tag = timer.mainTag else { continue }

            if let existing = tagData[tag.id] {
                tagData[tag.id] = (tag: existing.tag, totalTime: existing.totalTime + timer.totalElapsedSeconds, sessionCount: existing.sessionCount + 1)
            } else {
                tagData[tag.id] = (tag: tag, totalTime: timer.totalElapsedSeconds, sessionCount: 1)
            }
        }

        let totalTrackedTime = tagData.values.reduce(0) { $0 + $1.totalTime }

        // Calculate percentages based on total time (including untracked for daily view)
        let totalTimeForPercentage: TimeInterval
        if showUntrackedTime, case .daily = currentTimeFrame {
            let totalDayTime: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
            totalTimeForPercentage = totalDayTime
        } else {
            totalTimeForPercentage = totalTrackedTime
        }

        guard totalTimeForPercentage > 0 else { return [] }

        return tagData.values.map { (tag, time, count) in
            TagInsightData(
                tag: tag,
                totalTime: time,
                percentage: (time / totalTimeForPercentage) * 100,
                sessionCount: count
            )
        }.sorted { $0.totalTime > $1.totalTime }
    }

    private func calculateUntrackedTime(from tagData: [TagInsightData]) -> TagInsightData? {
        let totalTrackedTime = tagData.reduce(0) { $0 + $1.totalTime }
        let totalDayTime: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
        let untrackedTime = totalDayTime - totalTrackedTime

        guard untrackedTime > 0 else { return nil }

        // Create a dummy tag for untracked time
        let untrackedTag = Tag(name: "Untracked", color: "#808080", image: "clock.fill")

        return TagInsightData(
            tag: untrackedTag,
            totalTime: untrackedTime,
            percentage: (untrackedTime / totalDayTime) * 100,
            sessionCount: 1
        )
    }

    var hasData: Bool {
        !getInsightData().isEmpty
    }

    var totalTimeForPeriod: TimeInterval {
        getInsightData().reduce(0) { $0 + $1.totalTime }
    }
}
