//
//  Tracker.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/29/25.
//

import TelemetryDeck

enum Tracker {
    static func signal(_ name: String, params: [String: String]) {
        TelemetryDeck.signal(name, parameters: params)
    }
    
    static func signal(_ name: String) {
        TelemetryDeck.signal(name)
    }
}
