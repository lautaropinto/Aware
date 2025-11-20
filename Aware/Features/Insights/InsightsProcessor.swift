//
//  InsightsProcessor.swift
//  Aware
//
//  Created by Claude on 11/20/25.
//

import Foundation
import SwiftUI
import AwareData
import HealthKit

/// Pure functions for processing insights data
enum InsightsProcessor {

    // MARK: - Tag Aggregation

    /// Aggregates timeline entries by tag and calculates insights data
    static func aggregateByTag(
        _ entries: [any TimelineEntry],
        showUntrackedTime: Bool = false,
        timeFrame: TimeFrame
    ) -> [TagInsightData] {
        var tagData: [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)] = [:]
        var sleepTotalTime: TimeInterval = 0
        var sleepSessionCount: Int = 0
        var workoutTotalTime: TimeInterval = 0
        var workoutSessionCount: Int = 0

        // Process all entries
        for entry in entries {
            switch entry.type {
            case .timekeeper:
                guard let timekeeper = entry as? Timekeeper,
                      let tag = timekeeper.mainTag else { continue }

                if let existing = tagData[tag.id] {
                    tagData[tag.id] = (
                        tag: existing.tag,
                        totalTime: existing.totalTime + timekeeper.totalElapsedSeconds,
                        sessionCount: existing.sessionCount + 1
                    )
                } else {
                    tagData[tag.id] = (
                        tag: tag,
                        totalTime: timekeeper.totalElapsedSeconds,
                        sessionCount: 1
                    )
                }

            case .sleep:
                sleepTotalTime += entry.duration
                sleepSessionCount += 1

            case .workout:
                workoutTotalTime += entry.duration
                workoutSessionCount += 1
            }
        }

        let totalTrackedTime = tagData.values.reduce(0) { $0 + $1.totalTime } + sleepTotalTime + workoutTotalTime

        // Add synthetic tags for health data
        addSleepTag(sleepTotalTime, sleepSessionCount, to: &tagData)
        addWorkoutTag(workoutTotalTime, workoutSessionCount, to: &tagData)

        // Calculate percentages and create insight data
        var insightData = createInsightData(
            from: tagData,
            totalTrackedTime: totalTrackedTime,
            showUntrackedTime: showUntrackedTime,
            timeFrame: timeFrame
        )

        // Add untracked time for daily view if needed
        if showUntrackedTime, case .daily = timeFrame {
            if let untrackedData = calculateUntrackedTime(from: insightData) {
                insightData.append(untrackedData)
            }
        }

        return insightData.sorted(by: { $0.tag.displayOrder < $1.tag.displayOrder })
    }

    // MARK: - Percentage Calculations

    /// Calculates percentages based on total time
    static func calculatePercentages(
        tagData: [TagInsightData],
        totalTime: TimeInterval,
        showUntrackedTime: Bool,
        timeFrame: TimeFrame
    ) -> [TagInsightData] {
        let totalTimeForPercentage: TimeInterval
        if showUntrackedTime, case .daily = timeFrame {
            let totalDayTime: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
            totalTimeForPercentage = totalDayTime
        } else {
            totalTimeForPercentage = totalTime
        }

        guard totalTimeForPercentage > 0 else { return [] }

        return tagData.map { data in
            TagInsightData(
                tag: data.tag,
                totalTime: data.totalTime,
                percentage: (data.totalTime / totalTimeForPercentage) * 100,
                sessionCount: data.sessionCount
            )
        }
    }

    // MARK: - Untracked Time Calculation

    /// Calculates untracked time for daily view
    static func calculateUntrackedTime(from tagData: [TagInsightData]) -> TagInsightData? {
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

    // MARK: - Private Helper Methods

    private static func addSleepTag(
        _ sleepTotalTime: TimeInterval,
        _ sleepSessionCount: Int,
        to tagData: inout [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)]
    ) {
        guard sleepTotalTime > 0 else { return }

        let sleepTag = Tag(name: "Sleep", color: .sleepColor, image: "bed.double.fill")
        tagData[sleepTag.id] = (tag: sleepTag, totalTime: sleepTotalTime, sessionCount: sleepSessionCount)
    }

    private static func addWorkoutTag(
        _ workoutTotalTime: TimeInterval,
        _ workoutSessionCount: Int,
        to tagData: inout [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)]
    ) {
        guard workoutTotalTime > 0 else { return }

        let workoutTag = Tag(name: "Workouts", color: .workoutColor, image: "figure.mixed.cardio")
        tagData[workoutTag.id] = (tag: workoutTag, totalTime: workoutTotalTime, sessionCount: workoutSessionCount)
    }

    private static func createInsightData(
        from tagData: [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)],
        totalTrackedTime: TimeInterval,
        showUntrackedTime: Bool,
        timeFrame: TimeFrame
    ) -> [TagInsightData] {
        let totalTimeForPercentage: TimeInterval
        if showUntrackedTime, case .daily = timeFrame {
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
}

// TagInsightData is now defined in the main InsightStore.swift file