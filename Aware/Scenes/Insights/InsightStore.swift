//
//  InsightStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI
import SwiftData
import AwareData

struct TagInsightData: Identifiable {
    let id = UUID()
    let tag: Tag
    let totalTime: TimeInterval
    let percentage: Double
}

@Observable
class InsightStore {
    var currentTimeFrame: TimeFrame = .currentWeek
    var showUntrackedTime: Bool = false

    private var modelContext: ModelContext?

    init() {}

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

            return tagData
        } catch {
            print("Failed to fetch timers: \(error)")
            return []
        }
    }

    private func aggregateTimersByTag(_ timers: [Timekeeper]) -> [TagInsightData] {
        var tagTimes: [UUID: (tag: Tag, totalTime: TimeInterval)] = [:]

        for timer in timers {
            guard let tag = timer.mainTag else { continue }

            if let existing = tagTimes[tag.id] {
                tagTimes[tag.id] = (tag: existing.tag, totalTime: existing.totalTime + timer.totalElapsedSeconds)
            } else {
                tagTimes[tag.id] = (tag: tag, totalTime: timer.totalElapsedSeconds)
            }
        }

        let totalTrackedTime = tagTimes.values.reduce(0) { $0 + $1.totalTime }

        // Calculate percentages based on total time (including untracked for daily view)
        let totalTimeForPercentage: TimeInterval
        if showUntrackedTime, case .daily = currentTimeFrame {
            let totalDayTime: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
            totalTimeForPercentage = totalDayTime
        } else {
            totalTimeForPercentage = totalTrackedTime
        }

        guard totalTimeForPercentage > 0 else { return [] }

        return tagTimes.values.map { (tag, time) in
            TagInsightData(
                tag: tag,
                totalTime: time,
                percentage: (time / totalTimeForPercentage) * 100
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
            percentage: (untrackedTime / totalDayTime) * 100
        )
    }

    var hasData: Bool {
        !getInsightData().isEmpty
    }

    var totalTimeForPeriod: TimeInterval {
        getInsightData().reduce(0) { $0 + $1.totalTime }
    }
}
