//
//  AwarenessHomeStore.swift
//  Aware
//
//  Created by Codex on 4/22/26.
//

import Foundation
import Observation
import AwareData
import HealthKit
import OSLog

private let awarenessHomeLogger = Logger(subsystem: "Aware", category: "AwarenessHomeStore")

@Observable
final class AwarenessHomeStore {
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var timers: [Timekeeper] = []
    private var sleepData: [HKCategorySample] = []
    private var workoutData: [HKWorkout] = []
    private var storage: Storage?
    private var healthKitManager: HealthKitManager?

    func configure(storage: Storage, healthKitManager: HealthKitManager) {
        self.storage = storage
        self.healthKitManager = healthKitManager
    }

    func refreshData(for date: Date = .now) {
        Task {
            await loadTodayData(for: date)
        }
    }

    func summary(at date: Date = .now) -> AwarenessTimeSummary {
        AwarenessHomeProcessor.summary(
            now: date,
            timers: timers,
            sleepData: sleepData,
            workoutData: workoutData
        )
    }

    @MainActor
    private func loadTodayData(for date: Date) async {
        guard let storage else {
            awarenessHomeLogger.error("Storage not configured")
            return
        }

        isLoading = true
        errorMessage = nil

        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let dateInterval = DateInterval(start: dayStart, end: dayEnd)

        timers = storage.fetchTimers().filter { timer in
            guard timer.creationDate < dayEnd else { return false }

            if timer.endTime == nil {
                return true
            }

            if let endTime = timer.endTime {
                return endTime >= dayStart
            }

            return Calendar.current.isDate(timer.creationDate, inSameDayAs: dayStart)
        }

        var fetchedSleepData: [HKCategorySample] = []
        var fetchedWorkoutData: [HKWorkout] = []

        if let healthKitManager {
            do {
                if healthKitManager.hasSleepPermissions() {
                    fetchedSleepData = try await healthKitManager.fetchSleepData(for: dateInterval)
                }

                if healthKitManager.hasWorkoutPermissions() {
                    fetchedWorkoutData = try await healthKitManager.fetchWorkoutData(for: dateInterval)
                }
            } catch {
                errorMessage = "Some health data could not be loaded."
                awarenessHomeLogger.error("Failed to load Awareness Mode health data: \(error)")
            }
        }

        sleepData = fetchedSleepData
        workoutData = fetchedWorkoutData
        isLoading = false
    }
}
