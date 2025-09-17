//
//  Timer.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
public class Timekeeper {
    public var id: UUID = UUID()
    public var name: String = ""
    public var creationDate: Date = Date.now
    public var startTime: Date?
    public var endTime: Date?
    public var totalElapsedSeconds: TimeInterval = 0
    public var isRunning: Bool = false
    public var tag: Tag?
    
    public init(name: String, tag: Tag? = nil) {
        self.id = UUID()
        self.name = name
        self.creationDate = Date()
        self.startTime = nil
        self.endTime = nil
        self.totalElapsedSeconds = 0
        self.isRunning = false
        self.tag = tag
    }
    
    // MARK: - Timer Control Methods
    
    public func start() {
        guard !isRunning else { return }
        startTime = Date()
        isRunning = true
    }
    
    public func stop() {
        if isRunning, let startTime = startTime {
            // Timer is running, add current session time
            let sessionTime = Date().timeIntervalSince(startTime)
            totalElapsedSeconds += sessionTime
            self.startTime = nil
        }
        // Set end time and stop the timer (works for both running and paused states)
        endTime = Date()
        isRunning = false
    }
    
    public func pause() {
        guard isRunning, let startTime = startTime else { return }
        let sessionTime = Date().timeIntervalSince(startTime)
        totalElapsedSeconds += sessionTime
        isRunning = false
        self.startTime = nil
    }
    
    public func resume() {
        guard !isRunning else { return }
        startTime = Date()
        isRunning = true
    }
    
    public func reset() {
        startTime = nil
        endTime = nil
        totalElapsedSeconds = 0
        isRunning = false
    }
    
    // MARK: - Computed Properties
    
    public var currentElapsedTime: TimeInterval {
        var elapsed = totalElapsedSeconds
        if isRunning, let startTime = startTime {
            elapsed += Date().timeIntervalSince(startTime)
        }
        return elapsed
    }
    
    public var formattedElapsedTime: String {
        let time = currentElapsedTime
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
