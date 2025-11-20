//
//  HealthKitManager.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//  Moved from HealthStore.swift by Claude on 11/20/25.
//

import HealthKit
import OSLog

private let logger = Logger(subsystem: "Aware", category: "HealthKitManager")

/// Manager for all HealthKit operations - handles permissions, data fetching, and caching
final class HealthKitManager: Sendable {

    static let shared: HealthKitManager = HealthKitManager()

    let healthStore = HKHealthStore()

    private var sleepDataCache: [Date: [HKCategorySample]] = [:]
    private var workoutDataCache: [Date: [HKWorkout]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.aware.healthstore.cache", attributes: .concurrent)

    private init() { }

    // MARK: - Permission Management
    func hasSleepPermissions() -> Bool {
        let hasPermission = UserDefaults.standard.bool(for: .UserDefault.hasGrantedSleepReadPermission)
        logger.debug("UserDefaults sleep permission status: \(hasPermission)")

        return hasPermission
    }

    func hasWorkoutPermissions() -> Bool {
        let hasPermission = UserDefaults.standard.bool(for: .UserDefault.hasGrantedWorkoutReadPermission)
        logger.debug("UserDefaults workout permission status: \(hasPermission)")

        return hasPermission
    }

    func requestSleepPermissions() {
        logger.debug("Trying to request sleep permissions")
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedSleepReadPermission)
            
            return
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let workout = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [sleepType, workout]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                logger.debug("HealthKit auth result: \(success)")
                UserDefaults.standard.setBool(true, for: .UserDefault.hasGrantedSleepReadPermission)
                UserDefaults.standard.setBool(true, for: .UserDefault.hasGrantedWorkoutReadPermission)
            } else if let error {
                logger.error("HealthKit authorization failed: \(error.localizedDescription)")
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedSleepReadPermission)
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)
            } else {
                logger.error("Permission denied")
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedSleepReadPermission)
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)
            }
        }
    }

    func requestWorkoutPermissions() {
        logger.debug("Trying to request workout permissions")
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)

            return
        }

        let workoutType = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [workoutType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                logger.debug("HealthKit workout auth result: \(success)")
                UserDefaults.standard.setBool(true, for: .UserDefault.hasGrantedWorkoutReadPermission)
            } else if let error {
                logger.error("HealthKit workout authorization failed: \(error.localizedDescription)")
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)
            } else {
                logger.error("Workout permission denied")
                UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)
            }
        }
    }

    // MARK: - Sleep Data Fetching

    func fetchSleepData(for dateInterval: DateInterval) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitManagerError.invalidSleepType
        }

        guard hasSleepPermissions() else {
            throw HealthKitManagerError.permissionDenied
        }

        // Check cache first
        let cacheKey = Calendar.current.startOfDay(for: dateInterval.start)
        if let cachedData = getCachedSleepData(for: cacheKey) {
            logger.debug("Returning cached sleep data for \(cacheKey)")
            return cachedData
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dateInterval.start,
            end: dateInterval.end,
            options: [.strictStartDate, .strictEndDate]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { [weak self] query, samples, error in

                if let error = error {
                    logger.error("Failed to fetch sleep data: \(error)")

                    // Check if this is a permission error and reset the flag if needed
                    if let hkError = error as? HKError,
                       hkError.code == .errorAuthorizationDenied || hkError.code == .errorAuthorizationNotDetermined {
                        logger.info("Sleep data access was denied or revoked, resetting permission flag")
                        UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedSleepReadPermission)
                    }

                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples?.compactMap { $0 as? HKCategorySample } ?? []

                // Cache the results
                self?.cacheSleepData(sleepSamples, for: cacheKey)

                continuation.resume(returning: sleepSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Workout Data Fetching

    func fetchWorkoutData(for dateInterval: DateInterval) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()

        guard hasWorkoutPermissions() else {
            throw HealthKitManagerError.permissionDenied
        }

        // Check cache first
        let cacheKey = Calendar.current.startOfDay(for: dateInterval.start)
        if let cachedData = getCachedWorkoutData(for: cacheKey) {
            logger.debug("Returning cached workout data for \(cacheKey)")
            return cachedData
        }

        let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 0)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: dateInterval.start,
            end: dateInterval.end,
            options: [.strictStartDate, .strictEndDate]
        )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { [weak self] query, samples, error in

                if let error = error {
                    logger.error("Failed to fetch workout data: \(error)")

                    // Check if this is a permission error and reset the flag if needed
                    if let hkError = error as? HKError,
                       hkError.code == .errorAuthorizationDenied || hkError.code == .errorAuthorizationNotDetermined {
                        logger.info("Workout data access was denied or revoked, resetting permission flag")
                        UserDefaults.standard.setBool(false, for: .UserDefault.hasGrantedWorkoutReadPermission)
                    }

                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples?.compactMap { $0 as? HKWorkout } ?? []

                // Cache the results
                self?.cacheWorkoutData(workouts, for: cacheKey)

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Cache Management

    private func getCachedSleepData(for date: Date) -> [HKCategorySample]? {
        return cacheQueue.sync {
            sleepDataCache[date]
        }
    }

    private func cacheSleepData(_ samples: [HKCategorySample], for date: Date) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.sleepDataCache[date] = samples

            // Keep cache size manageable (last 30 days)
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            self?.sleepDataCache = self?.sleepDataCache.filter { $0.key >= cutoffDate } ?? [:]
        }
    }

    private func getCachedWorkoutData(for date: Date) -> [HKWorkout]? {
        return cacheQueue.sync {
            workoutDataCache[date]
        }
    }

    private func cacheWorkoutData(_ workouts: [HKWorkout], for date: Date) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.workoutDataCache[date] = workouts

            // Keep cache size manageable (last 30 days)
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            self?.workoutDataCache = self?.workoutDataCache.filter { $0.key >= cutoffDate } ?? [:]
        }
    }
}

enum HealthKitManagerError: Error, LocalizedError {
    case invalidSleepType
    case invalidWorkoutType
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidSleepType:
            return "Unable to access sleep analysis data type"
        case .invalidWorkoutType:
            return "Unable to access workout data type"
        case .permissionDenied:
            return "Permission to access health data was denied"
        }
    }
}
