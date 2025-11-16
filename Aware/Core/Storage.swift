//
//  Storage.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import Foundation
import SwiftData
import Observation
import AwareData
import Combine
import HealthKit
import OSLog

private var logger = Logger(subsystem: "Aware", category: "Storage")

@Observable
final class Storage {
    var tags: [Tag] = []
    var timers: [Timekeeper] = []
    var timer: Timekeeper?
    var sleepData: [HKCategorySample] = []
    var workoutData: [HKWorkout] = []
    
    
    private var hasLoadedHealthData = false
    private var hasSleepPermission = UserDefaults.standard.bool(forKey: .UserDefault.hasGrantedSleepReadPermission)
    private var hasWorkoutPermission = UserDefaults.standard.bool(forKey: .UserDefault.hasGrantedWorkoutReadPermission)
    
    var modelContext: ModelContext! {
        didSet {
            fetchTags()
            fetchActiveTimer()
            fetchTimers()
            loadHealthDataIfNeeded()
        }
    }
    
    private func fetchTags() {
        print("Sran dale capo")
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.displayOrder, order: .reverse)])
        tags = try! modelContext.fetch(descriptor)
        print("Result: \(tags.count)")
    }
    
    private func fetchActiveTimer() {
        let predicate = #Predicate<Timekeeper> {
            $0.endTime == nil
        }
        
        let descriptor = FetchDescriptor<Timekeeper>(predicate: predicate)
        let timers = try! modelContext.fetch(descriptor)
        self.timer = timers.first
    }
    
    func fetchTimers(_ predicate: Predicate<Timekeeper>? = nil) {
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.creationDate)])
        self.timers = try! modelContext.fetch(descriptor)
        print("Timers fetched: \(timers.count)")
    }
    
    func getTimers(_ predicate: Predicate<Timekeeper>) -> [Timekeeper] {
        let descriptor = FetchDescriptor(predicate: predicate)
        let timers = try! modelContext.fetch(descriptor)
        
        return timers
    }
    
    func startNewTimer(with tag: Tag) {
        let timer = Timekeeper(name: "\(tag.name) Session", tags: [tag])
        modelContext.insert(timer)
        timer.start()
        try? modelContext.save()
        fetchActiveTimer()
    }
    
    func firstTimekeeperDate() -> Date? {
        return timers.min(by: { $0.creationDate < $1.creationDate })?.creationDate
    }
}

extension Storage {
    func loadHealthDataIfNeeded() {
        guard !hasLoadedHealthData else { return }
        hasLoadedHealthData = true

        Task {
            await withTaskGroup(of: Void.self) { group in
                // Load sleep data in background
                group.addTask {
                    await self.loadSleepData()
                }

                // Load workout data in background
                group.addTask {
                    await self.loadWorkoutData()
                }
            }
        }
    }
    
    private func loadSleepData() async {
        guard hasSleepPermission else { return }

        // Don't load sleep data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load sleep data.")
            sleepData = []
            return
        }

        do {
            let endDate = Date()
            let dateInterval = DateInterval(start: firstDate, end: endDate)

            let fetchedSleepData = try await HealthStore.shared.fetchSleepData(for: dateInterval)

            logger.debug("Sleep data. \(fetchedSleepData.count)")
            self.sleepData = fetchedSleepData
        } catch {
            logger.error("Error loading sleep data. Error: \(error)")
            self.sleepData = []
        }
    }

    private func loadWorkoutData() async {
        guard hasWorkoutPermission else { return }

        // Don't load workout data if there are no timekeepers
        guard let firstDate = firstTimekeeperDate() else {
            logger.debug("No timekeepers found. Will not load workout data.")
            workoutData = []
            return
        }

        do {
            let endDate = Date()
            let dateInterval = DateInterval(start: firstDate, end: endDate)

            let fetchedWorkoutData = try await HealthStore.shared.fetchWorkoutData(for: dateInterval)

            logger.debug("Workout data. \(fetchedWorkoutData.count)")
            self.workoutData = fetchedWorkoutData
        } catch {
            logger.error("Error loading workout data. Error: \(error)")
            self.workoutData = []
        }
    }
}
