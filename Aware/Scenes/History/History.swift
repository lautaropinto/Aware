//
//  History.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/16/25.
//

import Foundation
import AwareData
import Observation
import SwiftData
import HealthKit
import OSLog
import SwiftUI

private var logger = Logger(subsystem: "History", category: "Logic")

struct DailySleepEntry: TimelineEntry {
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

@Observable
final class History {
    var filterBy: Tag? = nil {
        didSet {
            updateFilteredData()
        }
    }

    // Processed data properties
    private(set) var aggregatedSleepEntries: [DailySleepEntry] = []
    private(set) var combinedEntries: [any TimelineEntry] = []
    private(set) var groupedEntries: [Date: [any TimelineEntry]] = [:]
    private(set) var sortedDates: [Date] = []

    // Source data
    private var timers: [Timekeeper] = []
    private var sleepData: [HKCategorySample] = []
    private var workoutData: [HKWorkout] = []

    func processData(timers: [Timekeeper], sleepData: [HKCategorySample], workoutData: [HKWorkout]) {
        logger.debug("Processing history data - Timers: \(timers.count), Sleep: \(sleepData.count), Workouts: \(workoutData.count)")

        self.timers = timers
        self.sleepData = sleepData
        self.workoutData = workoutData

        processAggregatedSleepEntries()
        processCombinedEntries()
        updateFilteredData()
    }

    private func processAggregatedSleepEntries() {
        let groupedSleep = Dictionary(grouping: sleepData) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }

        aggregatedSleepEntries = groupedSleep.compactMap { (date, samples) -> DailySleepEntry? in
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

    private func processCombinedEntries() {
        var entries: [any TimelineEntry] = timers
        entries.append(contentsOf: aggregatedSleepEntries)
        entries.append(contentsOf: workoutData)
        combinedEntries = entries
    }

    private func updateFilteredData() {
        let filteredEntries: [any TimelineEntry]

        if let selectedTag = filterBy {
            // When filtering by tag, only show Timekeeper entries with that tag
            filteredEntries = timers.filter { $0.mainTag?.id == selectedTag.id }
        } else {
            filteredEntries = combinedEntries
        }

        // Group entries by day
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            Calendar.current.startOfDay(for: entry.creationDate)
        }

        // Sort entries within each day
        groupedEntries = grouped.mapValues { entries in
            entries.sorted(by: { $0.creationDate > $1.creationDate })
        }

        // Sort dates
        sortedDates = groupedEntries.keys.sorted(by: >)
    }

    func sortedTimers(for date: Date) -> [any TimelineEntry] {
        return groupedEntries[date] ?? []
    }
}
