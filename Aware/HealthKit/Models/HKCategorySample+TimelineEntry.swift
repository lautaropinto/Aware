//
//  HKCategorySample+TimelineEntry.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import Foundation
import HealthKit
import SwiftUI
import AwareData

extension String {
    static let sleepColor = "#6155f5"
}

extension HKCategorySample: @retroactive TimelineEntry {
    public var id: UUID {
        UUID(uuidString: uuid.uuidString) ?? UUID()
    }

    public var name: String {
        guard categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else {
            return "Unknown"
        }

        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .inBed:
            return "In Bed"
        case .asleepCore:
            return "Core Sleep"
        case .asleepDeep:
            return "Deep Sleep"
        case .asleepREM:
            return "REM Sleep"
        case .awake:
            return "Awake"
        case .asleepUnspecified:
            return "Sleep"
        default:
            return "Sleep"
        }
    }

    public var creationDate: Date {
        startDate
    }

    public var startTime: Date? {
        startDate
    }

    public var endTime: Date? {
        endDate
    }

    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    public var swiftUIColor: Color {
        guard categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
              let color = Color(hex: .sleepColor) else {
            return .gray
        }

        return color
    }

    public var image: String {
        guard categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else {
            return "questionmark"
        }

        
        return "moon.fill"
    }

    public var type: TimelineEntryType {
        .sleep
    }
}
