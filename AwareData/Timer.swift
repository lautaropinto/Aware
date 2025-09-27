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
public class Timekeeper: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, creationDate, startTime, endTime, totalElapsedSeconds, isRunning, tags
    }
    public var id: UUID = UUID()
    public var name: String = ""
    public var creationDate: Date = Date.now
    public var startTime: Date?
    public var endTime: Date?
    public var totalElapsedSeconds: TimeInterval = 0
    public var isRunning: Bool = false
    public var tags: [Tag]? = []
    
    public init(name: String, tags: [Tag] = []) {
        self.id = UUID()
        self.name = name
        self.creationDate = Date()
        self.startTime = nil
        self.endTime = nil
        self.totalElapsedSeconds = 0
        self.isRunning = false
        self.tags = tags
    }
    
    // MARK: - Timer Control Methods
    
    public var mainTag: Tag? {
        tags?.first
    }
    
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
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
//        id: UUID = UUID()
//        name: String = ""
//        creationDate: Date = Date.now
//        startTime: Date?
//        endTime: Date?
//        totalElapsedSeconds: TimeInterval = 0
//        isRunning: Bool = false
//        tags: [Tag]? = []

        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decode(Date?.self, forKey: .endTime)
        self.totalElapsedSeconds = try container.decode(TimeInterval.self, forKey: .totalElapsedSeconds)
        self.isRunning = try container.decode(Bool.self, forKey: .isRunning)
        self.tags = try container.decode([Tag]?.self, forKey: .tags)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(totalElapsedSeconds, forKey: .totalElapsedSeconds)
        try container.encode(isRunning, forKey: .isRunning)
        try container.encode(tags, forKey: .tags)
    }
}
