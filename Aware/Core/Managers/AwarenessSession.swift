//
//  AwarenessSession.swift
//  Aware
//
//  Created by Claude on 11/20/25.
//

import Foundation
import SwiftUI
import Observation
import AwareData
import AwareUI
import OSLog

private var logger = Logger(subsystem: "Aware", category: "AwarenessSession")

@Observable
final class AwarenessSession {
    static let shared = AwarenessSession()

    // MARK: - Public State
    private(set) var activeTimer: Timekeeper?
    private(set) var isTimerRunning: Bool = false

    // MARK: - Dependencies
    private var storage: Storage?
    private var liveActivityManager: LiveActivityManager?
    private var appConfig: CrossConfig?

    private init() {}

    // MARK: - Configuration
    func configure(storage: Storage, liveActivityManager: LiveActivityManager, appConfig: CrossConfig) {
        self.storage = storage
        self.liveActivityManager = liveActivityManager
        self.appConfig = appConfig

        // Check for existing active timer on startup
        loadActiveTimerIfNeeded()
    }

    // MARK: - Public Timer Operations

    func startTimer(with tag: Tag) {
        Tracker.signal("awareness.start_timer")
        guard let storage = storage else {
            logger.error("Storage not configured")
            return
        }

        logger.debug("Starting timer for tag: \(tag.name)")

        // Create new timer
        let timer = Timekeeper(name: "\(tag.name) Session", tags: [tag])
        storage.insert(timer)
        timer.start()
        storage.save()

        // Update session state
        activeTimer = timer
        isTimerRunning = true

        // Coordinate with other managers
        updateAppConfig(with: timer)
        startLiveActivity(with: timer)

        logger.debug("Timer started successfully: \(timer.formattedElapsedTime)")
    }

    func pauseTimer() {
        Tracker.signal("awareness.pause_timer")
        guard let timer = activeTimer, timer.isRunning else {
            logger.warning("No active running timer to pause")
            return
        }

        logger.debug("Pausing timer: \(timer.name)")

        timer.pause()
        storage?.save()
        isTimerRunning = false

        updateLiveActivity(with: timer, action: .pause)
        storage?.triggerRefresh()

        logger.debug("Timer paused: \(timer.formattedElapsedTime)")
    }

    func resumeTimer() {
        Tracker.signal("awareness.resume_timer")
        guard let timer = activeTimer, !timer.isRunning else {
            logger.warning("No paused timer to resume")
            return
        }

        logger.debug("Resuming timer: \(timer.name)")

        timer.resume()
        storage?.save()
        isTimerRunning = true

        updateLiveActivity(with: timer, action: .resume)
        storage?.triggerRefresh()

        logger.debug("Timer resumed: \(timer.formattedElapsedTime)")
    }

    func stopTimer() {
        Tracker.signal("awareness.stop_timer")
        guard let timer = activeTimer else {
            logger.warning("No active timer to stop")
            return
        }

        logger.debug("Stopping timer: \(timer.name)")
        timer.stop()
        storage?.save()
        
        let finalElapsedTime = timer.totalElapsedSeconds // Get final time before stopping

        // Update Live Activity to show completed state with final elapsed time
        liveActivityManager?.updateLiveActivity(
            elapsedTime: finalElapsedTime,
            intentAction: .stop
        )

        // Reset session state
        activeTimer = nil
        isTimerRunning = false

        // Coordinate with other managers
        resetAppConfig()

        // Keep Live Activity alive to show completion - no auto-dismissal

        // Trigger refresh and notification
        storage?.triggerRefresh()
        NotificationCenter.default.post(name: .timerDidStop, object: nil)

        logger.debug("Timer stopped successfully")
    }

    // MARK: - Lifecycle Management

    func resumeIfNeeded() {
        loadActiveTimerIfNeeded()

        guard let timer = activeTimer else { return }

        logger.debug("Resuming session with existing timer: \(timer.name)")

        isTimerRunning = timer.isRunning
        updateAppConfig(with: timer)
        startLiveActivity(with: timer)
    }

    // MARK: - Private Methods

    private func loadActiveTimerIfNeeded() {
        guard let storage = storage else { return }

        activeTimer = storage.fetchActiveTimer()
        isTimerRunning = activeTimer?.isRunning ?? false
    }

    private func updateAppConfig(with timer: Timekeeper) {
        guard let appConfig = appConfig else { return }

        appConfig.isTimerRunning = true
        appConfig.updateColor(timer.swiftUIColor)
    }

    private func resetAppConfig() {
        guard let appConfig = appConfig else { return }

        appConfig.isTimerRunning = false
        appConfig.updateColor(.accent)
    }

    private func startLiveActivity(with timer: Timekeeper) {
        liveActivityManager?.startLiveActivity(with: timer)
    }

    private func updateLiveActivity(with timer: Timekeeper, action: IntentAction) {
        liveActivityManager?.updateLiveActivity(
            elapsedTime: timer.currentElapsedTime,
            intentAction: action
        )
    }

    private func endLiveActivity() {
        liveActivityManager?.endLiveActivity()
    }

    private func endLiveActivityForTimer(_ timerId: UUID) {
        liveActivityManager?.endLiveActivityForTimer(timerId)
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let timerDidStop = Notification.Name("timerDidStop")
}

// IntentAction is defined in StopLiveIntent.swift
