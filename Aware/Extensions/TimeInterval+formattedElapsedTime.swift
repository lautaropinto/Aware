//
//  File.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import Foundation

extension TimeInterval {
    public static var halfHour = 1800.0
    
    public var formattedElapsedTime: String {
        let time = self
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    public var compactFormattedTime: String {
        let time = self
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension Int {
    static var oneHour: Int { 3600 }
    
}
