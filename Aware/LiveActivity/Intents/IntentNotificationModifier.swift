//
//  IntentNotificationModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/23/25.
//

import SwiftUI
import SwiftData
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "Intent Notification Receiver")

private struct IntentNotificationModifier: ViewModifier {
    @Environment(Storage.self) private var storage
    
    var timers: [Timekeeper] { storage.timers }
    
    @Environment(LiveActivityStore.self) var activityStore
    
    func body(content: Content) -> some View {
        let center = NotificationCenter.default
        content
            .onReceive(center.publisher(for: .stopTimer)) { notification in
                guard let timerID = notification.object as? String else {
                    logger.error("No timerID received")
                    return
                }
                
                handleStopTimer(timerID: timerID)
            }
            .onReceive(center.publisher(for: .pauseTimer)) { notification in
                guard let timerID = notification.object as? String else {
                    logger.error("No timerID received")
                    return
                }
                
                handlePauseTimer(timerID: timerID)
            }
            .onReceive(center.publisher(for: .resumeTimer)) { notification in
                guard let timerID = notification.object as? String else {
                    logger.error("No timerID received")
                    return
                }
                
                handleResumeTimer(timerID: timerID)
            }
            .onAppear {
                let today = Date.now.startOfDay
                let predicate = #Predicate<Timekeeper> {
                    $0.creationDate >= today
                }
                
                storage.fetchTimers(predicate)
            }
    }
    
    func handleStopTimer(timerID: String) {
        guard let timer = timers.first(where: { $0.id == UUID(uuidString: timerID) }) else {
            logger.error("No timer matching received ID. \(timerID)")
            return
        }
        
        guard timer.endTime == nil else {
            logger.error("Trying to stop an already stopped timer.")
            
            return
        }
        
        timer.stop()
        logger.debug("Stopping timer from stopTimer notification.")
        
        logger.debug("Ending live activity")
        activityStore.endLiveActivity()
    }
    
    func handlePauseTimer(timerID: String) {
        guard let timer = timers.first(where: { $0.id == UUID(uuidString: timerID) }) else {
            logger.error("No timer matching received ID. \(timerID)")
            return
        }
        
        
        timer.pause()
        logger.debug("Pausing timer from pauseTimer notification.")
        
        activityStore.updateLiveActivity(
            elapsedTime: timer.totalElapsedSeconds,
            intentAction: .pause
        )
    }
    
    func handleResumeTimer(timerID: String) {
        guard let timer = timers.first(where: { $0.id == UUID(uuidString: timerID) }) else {
            logger.error("No timer matching received ID. \(timerID)")
            return
        }
        
        timer.resume()
        logger.debug("Resuming timer from resumeTimer notification.")
        
        activityStore.updateLiveActivity(
            elapsedTime: timer.totalElapsedSeconds,
            intentAction: .resume
        )
    }
}

extension View {
    func setUpIntentNotificationListener() -> some View {
        modifier(IntentNotificationModifier())
    }
}
