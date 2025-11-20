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
    @Environment(AwarenessSession.self) private var awarenessSession

    var timers: [Timekeeper] { storage.timers }
    
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
        
        logger.debug("Stopping timer from stopTimer notification.")
        awarenessSession.stopTimer()
    }
    
    func handlePauseTimer(timerID: String) {
        guard let timer = timers.first(where: { $0.id == UUID(uuidString: timerID) }) else {
            logger.error("No timer matching received ID. \(timerID)")
            return
        }
        
        
        logger.debug("Pausing timer from pauseTimer notification.")
        awarenessSession.pauseTimer()
    }
    
    func handleResumeTimer(timerID: String) {
        guard let timer = timers.first(where: { $0.id == UUID(uuidString: timerID) }) else {
            logger.error("No timer matching received ID. \(timerID)")
            return
        }
        
        logger.debug("Resuming timer from resumeTimer notification.")
        awarenessSession.resumeTimer()
    }
}

extension View {
    func setUpIntentNotificationListener() -> some View {
        modifier(IntentNotificationModifier())
    }
}
