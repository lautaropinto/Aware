//
//  Storage.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//  Refactored by Claude on 11/20/25 to pure CRUD operations
//

import Foundation
import SwiftData
import Observation
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "Storage")

@Observable
final class Storage {
    static let shared = Storage()

    // MARK: - App State Properties
    var tags: [Tag] = []
    var timers: [Timekeeper] = []

    private var _context: ModelContext!
    private(set) var changeToken = UUID() // For triggering updates

    private init() {}

    func configure(context: ModelContext) {
        guard _context == nil else { fatalError("Storage already configured") }
        _context = context
        // Load initial data
        refreshTags()
        refreshTimers()
    }

    // MARK: - Change Notification

    func triggerRefresh() {
        changeToken = UUID()
    }
    
    // MARK: - Generic CRUD Operations

    func fetchAll<T: PersistentModel>(_ type: T.Type) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? _context.fetch(descriptor)) ?? []
    }

    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        return (try? _context.fetch(descriptor)) ?? []
    }

    // MARK: - State Refresh Methods

    func refreshTags() {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.displayOrder, order: .reverse)])
        tags = fetch(descriptor)
        triggerRefresh()
    }

    func refreshTimers() {
        let descriptor = FetchDescriptor<Timekeeper>(sortBy: [SortDescriptor(\.creationDate)])
        timers = fetch(descriptor)
        triggerRefresh()
    }

    func insert<T: PersistentModel>(_ model: T) {
        _context.insert(model)
    }

    func delete<T: PersistentModel>(_ model: T) {
        _context.delete(model)
    }

    func save() {
        do {
            try _context.save()
            refreshTags()
            refreshTimers()
            logger.debug("Storage saved successfully")
        } catch {
            logger.error("Failed to save storage: \(error)")
        }
    }

    // MARK: - Specific Data Operations

    func fetchTags() -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.displayOrder, order: .reverse)])
        return fetch(descriptor)
    }

    func fetchActiveTimer() -> Timekeeper? {
        let predicate = #Predicate<Timekeeper> {
            $0.endTime == nil
        }

        let descriptor = FetchDescriptor<Timekeeper>(predicate: predicate)
        return fetch(descriptor).first
    }

    func fetchTimers(_ predicate: Predicate<Timekeeper>? = nil) -> [Timekeeper] {
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.creationDate)])
        return fetch(descriptor)
    }

    func getTimers(_ predicate: Predicate<Timekeeper>) -> [Timekeeper] {
        let descriptor = FetchDescriptor(predicate: predicate)
        return fetch(descriptor)
    }

    func firstTimekeeperDate() -> Date? {
        let allTimers = fetchTimers()
        return allTimers.min(by: { $0.creationDate < $1.creationDate })?.creationDate
    }
}
