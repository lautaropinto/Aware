//
//  InsightStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//  Refactored by Claude on 11/20/25.
//

import SwiftUI
import SwiftData
import AwareData
import HealthKit
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
    // MARK: - UI State (Daily Only)
    var selectedDate: Date = Date().startOfDay
    var showUntrackedTime: Bool = false
    var sleepDataEnabled: Bool = false
    var workoutDataEnabled: Bool = false

    // MARK: - Data
    var insightData: [TagInsightData] = []

    // MARK: - Dependencies
    private var storage: Storage?
    private var healthKitManager: HealthKitManager?

    init() {
        loadUserDefaults()
    }

    // MARK: - Configuration
    func configure(storage: Storage, healthKitManager: HealthKitManager) {
        self.storage = storage
        self.healthKitManager = healthKitManager
    }

    // MARK: - Public Interface
    func updateDate(to newDate: Date) {
        selectedDate = newDate.startOfDay
        refreshData()
    }

    func updateShowUntrackedTime(to newValue: Bool) {
        showUntrackedTime = newValue
        UserDefaults.standard.set(newValue, forKey: .UserDefault.showUntrackedTime)
        refreshData()
    }

    func updateSleepDataVisibility(to isEnabled: Bool) {
        sleepDataEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: .UserDefault.sleepDataInsights)
        refreshData()
    }

    func updateWorkoutDataVisibility(to isEnabled: Bool) {
        workoutDataEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: .UserDefault.workoutDataInsights)
        refreshData()
    }

    func refreshData() {
        Task {
            let data = await loadDailyInsightData()
            await MainActor.run {
                self.insightData = data
            }
        }
    }

    private func loadDailyInsightData() async -> [TagInsightData] {
        guard let storage = storage else {
            logger.error("Storage not configured")
            return []
        }

        logger.debug("Loading daily insight data for: \(self.selectedDate)")

        // Get daily date range (start of day to end of day)
        let startOfDay = self.selectedDate
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        // Get timers for this day
        let predicate = #Predicate<Timekeeper> { timer in
            timer.creationDate >= startOfDay && timer.creationDate < endOfDay && timer.endTime != nil
        }
        let timers = storage.getTimers(predicate)

        // Get health data if enabled
        var sleepData: [HKCategorySample] = []
        var workoutData: [HKWorkout] = []

        if let healthKitManager = self.healthKitManager {
            let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
            do {
                if self.sleepDataEnabled {
                    sleepData = try await healthKitManager.fetchSleepData(for: dateInterval)
                }
                if self.workoutDataEnabled {
                    workoutData = try await healthKitManager.fetchWorkoutData(for: dateInterval)
                }
            } catch {
                logger.error("Failed to load health data: \(error)")
            }
        }

        // Create timeline entries
        var entries: [any TimelineEntry] = timers
        entries.append(contentsOf: sleepData)
        entries.append(contentsOf: workoutData)

        // Process using InsightsProcessor for daily view
        let insightData = InsightsProcessor.aggregateByTag(
            entries,
            showUntrackedTime: self.showUntrackedTime,
            timeFrame: .daily(self.selectedDate)
        )

        logger.debug("Generated \(insightData.count) insight items for \(self.selectedDate)")
        return insightData.sorted(by: { $0.tag.displayOrder < $1.tag.displayOrder })
    }

    var hasData: Bool {
        !insightData.isEmpty
    }

    var totalTimeForPeriod: TimeInterval {
        insightData.reduce(0) { $0 + $1.totalTime }
    }

    // MARK: - Private Methods

    private func loadUserDefaults() {
        showUntrackedTime = UserDefaults.standard.bool(forKey: .UserDefault.showUntrackedTime)

        // Set default to true if not previously set
        if !UserDefaults.standard.exists(key: .UserDefault.sleepDataInsights) {
            UserDefaults.standard.set(true, forKey: .UserDefault.sleepDataInsights)
        }
        sleepDataEnabled = UserDefaults.standard.bool(forKey: .UserDefault.sleepDataInsights)

        // Set default to true for workout data if not previously set
        if !UserDefaults.standard.exists(key: .UserDefault.workoutDataInsights) {
            UserDefaults.standard.set(true, forKey: .UserDefault.workoutDataInsights)
        }
        workoutDataEnabled = UserDefaults.standard.bool(forKey: .UserDefault.workoutDataInsights)
    }
}
