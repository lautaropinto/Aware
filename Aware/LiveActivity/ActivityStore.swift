//
//  ActivityStore.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/22/25.
//

import Foundation
import ActivityKit
import Observation
import AwareData
import OSLog
import SwiftData

private var logger = Logger(subsystem: "Aware", category: "ActivityStore")

@Observable
final class ActivityStore {
    var timer: Timekeeper?
    var activity: Activity<TimerAttributes>? = nil
    var modelContext: ModelContext?
    var isActivityRunning = false
    
    static func getLiveActivity(for timerID: UUID) -> Activity<TimerAttributes>? {
        Activity<TimerAttributes>.activities.first(where: {$0.attributes.timer.id == timerID})
    }
    
    func startLiveActivity(with timer: Timekeeper?) {
        guard let timer else {
            logger.info("No timer alive to start a liveActivity")
            
            return
        }
        
        guard ActivityStore.getLiveActivity(for: timer.id) == nil else {
            let formattedElapsedTime = timer.totalElapsedSeconds.formattedElapsedTime
            logger.info("Activity already ongoing with totalElapsedSeconds: \(formattedElapsedTime)")
            self.updateLiveActivity(elapsedTime: timer.currentElapsedTime, intentAction: .resume)
            
            return
        }
        
        let attributes = TimerAttributes(timer: timer)
        logger.debug("Initing activity with: \(timer.totalElapsedSeconds.formattedElapsedTime)")
        let initialState = TimerAttributes.ContentState(
            totalElapsedSeconds: timer.currentElapsedTime,
            eventDescription: "",
            intentAction: .resume
        )
        
        do {
            logger.debug("Requesting activity with name: \(attributes.timer.name)")
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil)
            )
            isActivityRunning = true
        } catch {
            logger.error("Error starting live activity: \(error)")
        }
    }
    
    func updateLiveActivity(elapsedTime: TimeInterval?, intentAction: IntentAction) {
        guard let timer else {
            logger.info("No timer alive to update the liveActivity")
            
            return
        }
        
        let updatedState = TimerAttributes.ContentState(
            totalElapsedSeconds: elapsedTime ?? timer.totalElapsedSeconds,
            eventDescription: "",
            intentAction: intentAction
        )
        
        Task {
            logger.debug("Updating activity with name: \(timer.name) - \(elapsedTime!.formattedElapsedTime)")
//            await activity?.update(.init(state: updatedState, staleDate: .now))
            await activity?.update(using: updatedState)
        }
    }
    
    func endLiveActivity(success: Bool = false) {
        guard let timer else {
            logger.info("No timer alive to end the liveActivity")
            
            return
        }
        
        let finalState = TimerAttributes.ContentState(
            totalElapsedSeconds: timer.totalElapsedSeconds,
            eventDescription: "",
            intentAction: .stop
        )
        
        Task {
            logger.info("Ending live activity.")
            await activity?.end(
                ActivityContent(state: finalState, staleDate: Date.now),
                dismissalPolicy: .default
            )
            isActivityRunning = false
        }
    }
}
