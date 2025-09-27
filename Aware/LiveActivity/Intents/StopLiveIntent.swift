//
//  StopIntent.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/22/25.
//

import AppIntents
import Foundation
import SwiftData
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "StopWatchLiveIntent")

public enum IntentAction: String, Codable {
    case stop, pause, resume
}

struct StopWatchLiveIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stops current running timer."

    @Parameter(title: "Timer ID")
    var timerID: String
    
    @Parameter(title: "Action")
    var action: String
    
    init(timerID: String, action: String) {
        self.action = action
        self.timerID = timerID
        logger.debug("Init. Receiving: \(action)")
    }
    
    init() { }
    
    func perform() async throws -> some IntentResult {
        let actionIntent = IntentAction(rawValue: action) ?? .stop
        Notification.stopwatch(timerID: self.timerID, action: actionIntent)
        
        logger.debug("Performing \(actionIntent.rawValue)")
        
        return .result()
    }
}
