//
//  IntentNotifications.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/23/25.
//

import Foundation

extension Notification.Name {
    static let stopTimer = Notification.Name("Aware.StopTimer")
    static let pauseTimer = Notification.Name("Aware.PauseTimer")
    static let resumeTimer = Notification.Name("Aware.ResumeTimer")
}

extension Notification {
    static func stopwatch(timerID: String, action: IntentAction) {
        let center = NotificationCenter.default
        
        DispatchQueue.main.async {
            switch action {
            case .pause:
                center.post(name: .pauseTimer, object: timerID)
            case .resume:
                center.post(name: .resumeTimer, object: timerID)
            case .stop:
                center.post(name: .stopTimer, object: timerID)
            }
        }
    }
}

