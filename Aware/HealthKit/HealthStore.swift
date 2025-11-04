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
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }
        return healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
    }

    func requestSleepPermissions() async -> Bool {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Failed to create sleep analysis type")
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
            let granted = hasSleepPermissions()

            UserDefaults.standard.set(true, forKey: .UserDefault.healthKitSleepPermissionsRequested)
            UserDefaults.standard.set(granted, forKey: .UserDefault.healthKitSleepPermissionsGranted)

            logger.info("Sleep permissions requested. Granted: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request sleep permissions: \(error)")
            return false
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
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples?.compactMap { $0 as? HKCategorySample } ?? []
                logger.info("Fetched \(sleepSamples.count) sleep samples")

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
