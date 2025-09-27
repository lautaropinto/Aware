//
//  Attributes.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/22/25.
//

import Foundation
import ActivityKit
import AwareData

public struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable & Hashable {
        public let totalElapsedSeconds: TimeInterval
        public let eventDescription: String
        public let intentAction: IntentAction
        
        public var timerInterval: ClosedRange<Date> {
            let startTime = Date(timeIntervalSinceNow: -totalElapsedSeconds)
            
            return startTime...Date(timeInterval: 3600000, since: .now)
        }
        
        public init(
            totalElapsedSeconds: TimeInterval,
            eventDescription: String,
            intentAction: IntentAction
        ) {
            self.totalElapsedSeconds = totalElapsedSeconds
            self.eventDescription = eventDescription
            self.intentAction = intentAction
        }
    }
    
    public let timer: Timekeeper
    
    public init(timer: Timekeeper) {
        self.timer = timer
    }
}
