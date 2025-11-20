//
//  HistoryProcessor.swift
//  Aware
//
//  Created by Claude on 11/20/25.
//

import Foundation
import SwiftUI
import AwareData
import HealthKit

/// Pure functions for processing history data
enum HistoryProcessor {

    // MARK: - Sleep Data Processing

    /// Aggregates sleep data samples into daily entries
    static func aggregateSleepEntries(from sleepData: [HKCategorySample]) -> [DailySleepEntry] {
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

    // MARK: - Timeline Combination

    /// Combines different types of timeline entries into a single array
    static func combinedTimelineEntries(
        timers: [Timekeeper],
        sleepEntries: [DailySleepEntry],
        workoutData: [HKWorkout]
    ) -> [any TimelineEntry] {
        var entries: [any TimelineEntry] = []
        entries.append(contentsOf: timers)
        entries.append(contentsOf: sleepEntries)
        entries.append(contentsOf: workoutData)
        return entries
    }

    // MARK: - Filtering

    /// Filters timeline entries by a specific tag
    static func filterEntries(
        _ entries: [any TimelineEntry],
        by tag: Tag?
    ) -> [any TimelineEntry] {
        guard let selectedTag = tag else {
            return entries
        }

        // When filtering by tag, only show Timekeeper entries with that tag
        return entries.compactMap { entry in
            if let timekeeper = entry as? Timekeeper {
                return timekeeper.mainTag?.id == selectedTag.id ? timekeeper : nil
            }
            return nil
        }
    }

    // MARK: - Grouping and Sorting

    /// Groups timeline entries by day and sorts them
    static func groupEntriesByDay(
        _ entries: [any TimelineEntry]
    ) -> (grouped: [Date: [any TimelineEntry]], sortedDates: [Date]) {

        // Group entries by day
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.creationDate)
        }

        // Sort entries within each day
        let groupedSorted = grouped.mapValues { entries in
            entries.sorted(by: { $0.creationDate > $1.creationDate })
        }

        // Sort dates
        let sortedDates = groupedSorted.keys.sorted(by: >)

        return (groupedSorted, sortedDates)
    }
}

// DailySleepEntry should be defined in a shared location