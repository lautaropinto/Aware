//
//  HealthStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//

import HealthKit
import OSLog

private let logger = Logger(subsystem: "Aware", category: "HealthStore")

/// A reference to the shared `HKHealthStore` for views to use.
final class HealthStore: Sendable {

    static let shared: HealthStore = HealthStore()

    let healthStore = HKHealthStore()

    private var sleepDataCache: [Date: [HKCategorySample]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.aware.healthstore.cache", attributes: .concurrent)

    private init() { }

    // MARK: - Permission Management

    func hasSleepPermissions() -> Bool {
        let hasPermission = UserDefaults.standard.bool(for: UserDefaults.Keys.hasGrantedSleepReadPermission)
        logger.debug("UserDefaults sleep permission status: \(hasPermission)")

        return hasPermission
    }

    func requestSleepPermissions() {
        logger.debug("Trying to request sleep permissions")
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            UserDefaults.standard.setBool(false, for: UserDefaults.Keys.hasGrantedSleepReadPermission)
            
            return
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                logger.debug("HealthKit auth result: \(success)")
                UserDefaults.standard.setBool(true, for: UserDefaults.Keys.hasGrantedSleepReadPermission)
            } else if let error {
                logger.error("HealthKit authorization failed: \(error.localizedDescription)")
                UserDefaults.standard.setBool(false, for: UserDefaults.Keys.hasGrantedSleepReadPermission)
            } else {
                logger.error("Permission denied")
                UserDefaults.standard.setBool(false, for: UserDefaults.Keys.hasGrantedSleepReadPermission)
            }
        }
    }

    // MARK: - Sleep Data Fetching

    func fetchSleepData(for dateInterval: DateInterval) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthStoreError.invalidSleepType
        }

        guard hasSleepPermissions() else {
            throw HealthStoreError.permissionDenied
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
                        UserDefaults.standard.setBool(false, for: UserDefaults.Keys.hasGrantedSleepReadPermission)
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
}

enum HealthStoreError: Error, LocalizedError {
    case invalidSleepType
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidSleepType:
            return "Unable to access sleep analysis data type"
        case .permissionDenied:
            return "Permission to access sleep data was denied"
        }
    }
}
