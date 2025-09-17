//
//  File.swift
//  AwareData
//
//  Created by Lautaro Pinto on 9/10/25.
//

import SwiftUI
import SwiftData

// MARK: - Tag Model

@Model
public class Tag: Codable {
    public var id: UUID = UUID()
    public var name: String = ""
    public var color: String = ""// Store color as hex string
    public var image: String = ""
    public var creationDate: Date = Date.now
    public var displayOrder: Int = 0// Custom order for reordering
    @Relationship(deleteRule: .nullify, inverse: \Timekeeper.tag) var timers: [Timekeeper]? = []
    
    public init(name: String, color: String = "#007AFF", image: String = "", displayOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.image = image
        self.creationDate = Date()
        self.displayOrder = displayOrder
        self.timers = []
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, creationDate, displayOrder, image
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.color = try container.decode(String.self, forKey: .color)
        self.image = try container.decode(String.self, forKey: .image)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        self.timers = []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(image, forKey: .image)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(displayOrder, forKey: .displayOrder)
    }
    
    // MARK: - Computed Properties
    
    public var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
    
    public var totalTimeSpent: TimeInterval {
        guard let timers else { return 0 }
        
        return timers.reduce(0) { total, timekeeper in
            total + timekeeper.totalElapsedSeconds
        }
    }
    
    public var activeTimersCount: Int {
        guard let timers else { return 0 }
        
        return timers.filter { $0.isRunning }.count
    }
    
    public var formattedTotalTime: String {
        let time = totalTimeSpent
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Predefined Tags
    
    @MainActor public static let defaultTags: [Tag] = [
        Tag(name: "Working", color: "#FF6B6B", displayOrder: 0),
        Tag(name: "Working Out", color: "#4ECDC4", displayOrder: 1),
        Tag(name: "Cooking", color: "#45B7D1", displayOrder: 2),
        Tag(name: "Traveling", color: "#96CEB4", displayOrder: 3),
        Tag(name: "Learning", color: "#FFEAA7", displayOrder: 4),
        Tag(name: "Reading", color: "#DDA0DD", displayOrder: 5),
        Tag(name: "Personal", color: "#98D8C8", displayOrder: 6)
    ]
}

// MARK: - Color Extension

public extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
