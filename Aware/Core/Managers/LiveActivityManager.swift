//
//  LiveActivityManager.swift
//  Aware
//
//  Created by Claude on 11/20/25.
//  Extracted from LiveActivityStore.swift
//

import Foundation
import ActivityKit
import Observation
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "LiveActivityManager")

@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    // MARK: - State
    private var activity: Activity<TimerAttributes>? = nil
    private(set) var isActivityRunning = false

    private init() {}

    // MARK: - Public Interface

    func startLiveActivity(with timer: Timekeeper) {
        logger.debug("Starting live activity for timer: \(timer.name)")

        // Check if activity already exists for this timer
        guard getLiveActivity(for: timer.id) == nil else {
            logger.info("Activity already exists, updating instead of creating new one")
            updateLiveActivity(
                elapsedTime: timer.currentElapsedTime,
                intentAction: timer.isRunning ? .resume : .pause
            )
            return
        }

        // Create new live activity
        let attributes = TimerAttributes(timer: timer)
        let initialState = TimerAttributes.ContentState(
            totalElapsedSeconds: timer.currentElapsedTime,
            eventDescription: "",
            intentAction: .resume
        )

        do {
            logger.debug("Requesting new live activity: \(timer.name)")
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            isActivityRunning = true
            logger.info("Live activity started successfully")
        } catch {
            logger.error("Error starting live activity: \(error)")
        }
    }

    func updateLiveActivity(elapsedTime: TimeInterval, intentAction: IntentAction) {
        guard let activity = activity else {
            logger.warning("No active live activity to update")
            return
        }

        let updatedState = TimerAttributes.ContentState(
            totalElapsedSeconds: elapsedTime,
            eventDescription: "",
            intentAction: intentAction
        )

        Task {
            logger.debug("Updating live activity - \(elapsedTime.formattedElapsedTime)")
            await activity.update(using: updatedState)
        }
    }

    func endLiveActivity() {
        guard let activity = activity else {
            logger.warning("No active live activity to end")
            return
        }

        Task {
            logger.info("Ending live activity")
            await activity.end(dismissalPolicy: .default)
            await MainActor.run {
                self.isActivityRunning = false
                self.activity = nil
            }
        }
    }

    // MARK: - Helper Methods

    private func getLiveActivity(for timerID: UUID) -> Activity<TimerAttributes>? {
        return Activity<TimerAttributes>.activities.first { $0.attributes.timer.id == timerID }
    }
}