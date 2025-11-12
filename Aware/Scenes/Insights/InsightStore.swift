//
//  InsightStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
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
    var currentTimeFrame: TimeFrame = .currentWeek
    // TimeFrame Picker info
    var selectedTimeFrame: TimeFrame = .currentWeek
    var selectedDayDate: Date = Date().startOfDay
    var selectedWeekDate: Date = Date().startOfWeek
    var selectedMonthDate: Date = Date().startOfMonth
    var selectedYearDate: Date = Date().startOfYear
    var showUntrackedTime: Bool = false
    var sleepDataEnabled: Bool = false
    var workoutDataEnabled: Bool = false

    private var sleepData: [HKCategorySample] = []
    private var workoutData: [HKWorkout] = []

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
            var entries: [any TimelineEntry] = timers
            entries.append(contentsOf: sleepData)
            entries.append(contentsOf: workoutData)
            var tagData = aggregateTimersByTag(entries)

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

    private func aggregateTimersByTag(_ entries: [any TimelineEntry]) -> [TagInsightData] {
        var tagData: [UUID: (tag: Tag, totalTime: TimeInterval, sessionCount: Int)] = [:]
        var sleepTotalTime: TimeInterval = 0
        var sleepSessionCount: Int = 0
        var workoutTotalTime: TimeInterval = 0
        var workoutSessionCount: Int = 0

        for entry in entries {
            switch entry.type {
            case .timekeeper:
                guard let timekeeper = entry as? Timekeeper,
                      let tag = timekeeper.mainTag else { continue }

                if let existing = tagData[tag.id] {
                    tagData[tag.id] = (tag: existing.tag, totalTime: existing.totalTime + timekeeper.totalElapsedSeconds, sessionCount: existing.sessionCount + 1)
                } else {
                    tagData[tag.id] = (tag: tag, totalTime: timekeeper.totalElapsedSeconds, sessionCount: 1)
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

        // Add sleep data as a synthetic tag if we have sleep data
        if sleepTotalTime > 0 {
            let sleepTag = Tag(name: "Sleep", color: .sleepColor, image: "bed.double.fill")
            let sleepTagData = (tag: sleepTag, totalTime: sleepTotalTime, sessionCount: sleepSessionCount)
            tagData[sleepTag.id] = sleepTagData
        }

        // Add workout data as a synthetic tag if we have workout data
        if workoutTotalTime > 0 {
            let workoutTag = Tag(name: "Workouts", color: .workoutColor, image: "figure.mixed.cardio")
            let workoutTagData = (tag: workoutTag, totalTime: workoutTotalTime, sessionCount: workoutSessionCount)
            tagData[workoutTag.id] = workoutTagData
        }

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

    // MARK: - Sleep Data Management

    private func firstTimekeeperDate() -> Date? {
        guard let modelContext = modelContext else { return nil }

        let descriptor = FetchDescriptor<Timekeeper>(
            sortBy: [SortDescriptor(\.creationDate, order: .forward)]
        )

        do {
            let timers = try modelContext.fetch(descriptor)
            return timers.first?.creationDate
        } catch {
            logger.error("Failed to fetch first timekeeper date: \(error)")
            return nil
        }
    }

    func loadSleepData() {
        guard sleepDataEnabled else {
            logger.debug("Sleep data disabled by user preference.")
            sleepData = []
            return
        }

        guard HealthStore.shared.hasSleepPermissions() else {
            logger.debug("No sleep permissions. Will not load sleep data.")
            sleepData = []
            return
        }

        // Don't load sleep data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load sleep data.")
            sleepData = []
            return
        }

        logger.debug("Loading sleep data for insights")

        Task {
            do {
                let dateInterval: DateInterval

                if let range = currentTimeFrame.dateRange {
                    // For specific time ranges, limit to first Timekeeper date if earlier
                    let startDate = max(range.start, firstDate)
                    dateInterval = DateInterval(start: startDate, end: range.end)
                } else {
                    // All time - fetch from first Timekeeper date onwards
                    let endDate = Date()
                    dateInterval = DateInterval(start: firstDate, end: endDate)
                }

                let fetchedSleepData = try await HealthStore.shared.fetchSleepData(for: dateInterval)

                await MainActor.run {
                    logger.debug("Loaded \(fetchedSleepData.count) sleep entries for insights")
                    self.sleepData = fetchedSleepData
                }
            } catch {
                logger.error("Error loading sleep data for insights: \(error)")
                await MainActor.run {
                    self.sleepData = []
                }
            }
        }
    }

    func updateSleepDataVisibility(to isEnabled: Bool) {
        sleepDataEnabled = isEnabled
        if isEnabled {
            loadSleepData()
        } else {
            sleepData = []
        }
    }

    // MARK: - Workout Data Management

    func loadWorkoutData() {
        guard workoutDataEnabled else {
            logger.debug("Workout data disabled by user preference.")
            workoutData = []
            return
        }

        guard HealthStore.shared.hasWorkoutPermissions() else {
            logger.debug("No workout permissions. Will not load workout data.")
            workoutData = []
            return
        }

        // Don't load workout data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load workout data.")
            workoutData = []
            return
        }

        logger.debug("Loading workout data for insights")

        Task {
            do {
                let dateInterval: DateInterval

                if let range = currentTimeFrame.dateRange {
                    // For specific time ranges, limit to first Timekeeper date if earlier
                    let startDate = max(range.start, firstDate)
                    dateInterval = DateInterval(start: startDate, end: range.end)
                } else {
                    // All time - fetch from first Timekeeper date onwards
                    let endDate = Date()
                    dateInterval = DateInterval(start: firstDate, end: endDate)
                }

                let fetchedWorkoutData = try await HealthStore.shared.fetchWorkoutData(for: dateInterval)

                await MainActor.run {
                    logger.debug("Loaded \(fetchedWorkoutData.count) workout entries for insights")
                    self.workoutData = fetchedWorkoutData
                }
            } catch {
                logger.error("Error loading workout data for insights: \(error)")
                await MainActor.run {
                    self.workoutData = []
                }
            }
        }
    }

    func updateWorkoutDataVisibility(to isEnabled: Bool) {
        workoutDataEnabled = isEnabled
        if isEnabled {
            loadWorkoutData()
        } else {
            workoutData = []
        }
    }
}
