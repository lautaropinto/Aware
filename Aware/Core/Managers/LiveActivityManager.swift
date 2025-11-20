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

        // Check if activity already exists for this timer in the system
        if let existingActivity = findExistingLiveActivity(for: timer.id) {
            logger.info("Activity already exists in system, updating instead of creating new one")
            activity = existingActivity
            isActivityRunning = true
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

        let eventDescription = intentAction == .stop ? "🎉 Session completed!" : ""
        let updatedState = TimerAttributes.ContentState(
            totalElapsedSeconds: elapsedTime,
            eventDescription: eventDescription,
            intentAction: intentAction
        )

        Task {
            let action = intentAction.rawValue
            logger.debug("Updating live activity - \(elapsedTime.formattedElapsedTime) with action: \(action)")
            await activity.update(using: updatedState)
        }
    }

    func endLiveActivity() {
        Task {
            logger.info("Ending live activity")

            // End all active timer live activities
            let allActivities = Activity<TimerAttributes>.activities
            logger.debug("Found \(allActivities.count) active activities to end")

            for activity in allActivities {
                logger.debug("Ending activity for timer: \(activity.attributes.timer.name)")
                await activity.end(dismissalPolicy: .default)
            }

            await MainActor.run {
                self.isActivityRunning = false
                self.activity = nil
            }

            logger.info("All live activities ended successfully")
        }
    }

    // MARK: - Helper Methods

    private func findExistingLiveActivity(for timerID: UUID) -> Activity<TimerAttributes>? {
        return Activity<TimerAttributes>.activities.first { $0.attributes.timer.id == timerID }
    }

    func endLiveActivityForTimer(_ timerID: UUID) {
        Task {
            logger.info("Ending live activity for specific timer: \(timerID)")

            // Find and end the specific timer's live activity
            let activities = Activity<TimerAttributes>.activities
            logger.debug("Found \(activities.count) total live activities to check")

            var foundActivity = false
            for activity in activities {
                logger.debug("Checking activity for timer ID: \(activity.attributes.timer.id)")
                if activity.attributes.timer.id == timerID {
                    logger.info("Found matching activity for timer: \(activity.attributes.timer.name), ending it...")
                    await activity.end(dismissalPolicy: .immediate)
                    foundActivity = true
                    break
                }
            }

            if !foundActivity {
                logger.warning("No live activity found for timer ID: \(timerID)")
            }

            // Update local state if this was our tracked activity
            if let currentActivity = self.activity, currentActivity.attributes.timer.id == timerID {
                await MainActor.run {
                    logger.debug("Clearing local activity state")
                    self.isActivityRunning = false
                    self.activity = nil
                }
            } else {
                logger.debug("Local activity state doesn't match timer ID or is nil")
            }
        }
    }
}
