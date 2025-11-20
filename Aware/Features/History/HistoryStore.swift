//
//  HistoryStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/16/25.
//  Renamed and refactored by Claude on 11/20/25.
//

import Foundation
import AwareData
import Observation
import SwiftData
import HealthKit
import OSLog
import SwiftUI

private var logger = Logger(subsystem: "History", category: "HistoryStore")

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
final class HistoryStore {
    var filterBy: Tag? = nil {
        didSet {
            refreshData()
        }
    }

    // Processed data properties
    private(set) var groupedEntries: [Date: [any TimelineEntry]] = [:]
    private(set) var sortedDates: [Date] = []

    // Dependencies
    private var storage: Storage?
    private var healthKitManager: HealthKitManager?

    init() {}

    func configure(storage: Storage, healthKitManager: HealthKitManager) {
        self.storage = storage
        self.healthKitManager = healthKitManager
    }

    // MARK: - Public Interface

    func refreshData() {
        Task {
            await loadAndProcessData()
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadAndProcessData() async {
        guard let storage = storage else {
            logger.error("Storage not configured")
            return
        }

        logger.debug("Loading history data")

        // Load timer data from storage
        let timers = storage.fetchTimers()

        // Load health data
        var sleepData: [HKCategorySample] = []
        var workoutData: [HKWorkout] = []

        if let healthKitManager = healthKitManager,
           let firstDate = storage.firstTimekeeperDate() {
            let endDate = Date()
            let dateInterval = DateInterval(start: firstDate, end: endDate)

            do {
                async let sleepTask = healthKitManager.fetchSleepData(for: dateInterval)
                async let workoutTask = healthKitManager.fetchWorkoutData(for: dateInterval)

                sleepData = try await sleepTask
                workoutData = try await workoutTask
            } catch {
                logger.error("Failed to load health data: \(error)")
            }
        }

        // Process data using HistoryProcessor
        let sleepEntries = HistoryProcessor.aggregateSleepEntries(from: sleepData)
        let combinedEntries = HistoryProcessor.combinedTimelineEntries(
            timers: timers,
            sleepEntries: sleepEntries,
            workoutData: workoutData
        )

        let filteredEntries = HistoryProcessor.filterEntries(combinedEntries, by: filterBy)
        let (grouped, dates) = HistoryProcessor.groupEntriesByDay(filteredEntries)

        // Update UI on main thread
        await MainActor.run {
            self.groupedEntries = grouped
            self.sortedDates = dates
        }

        logger.debug("History data processed - \(grouped.count) days")
    }

    func sortedTimers(for date: Date) -> [any TimelineEntry] {
        return groupedEntries[date] ?? []
    }
}