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

    private var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func updateTimeFrame(to newFrame: TimeFrame) {
        currentTimeFrame = newFrame
    }

    func getInsightData() -> [TagInsightData] {
        guard let modelContext = modelContext else { return [] }

        let descriptor: FetchDescriptor<Timekeeper>

        if let range = currentTimeFrame.dateRange {
            // Specific time range (week, month, year)
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
            return aggregateTimersByTag(timers)
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

        let totalTime = tagTimes.values.reduce(0) { $0 + $1.totalTime }
        guard totalTime > 0 else { return [] }

        return tagTimes.values.map { (tag, time) in
            TagInsightData(
                tag: tag,
                totalTime: time,
                percentage: (time / totalTime) * 100
            )
        }.sorted { $0.totalTime > $1.totalTime }
    }

    var hasData: Bool {
        !getInsightData().isEmpty
    }

    var totalTimeForPeriod: TimeInterval {
        getInsightData().reduce(0) { $0 + $1.totalTime }
    }
}
