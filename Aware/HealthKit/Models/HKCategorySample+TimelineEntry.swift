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
        guard categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else {
            return .gray
        }

        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .inBed:
            return Color.blue.opacity(0.3)
        case .asleepCore:
            return Color.blue
        case .asleepDeep:
            return Color.indigo
        case .asleepREM:
            return Color.purple
        case .awake:
            return Color.orange
        case .asleepUnspecified:
            return Color.blue
        default:
            return Color.blue
        }
    }

    public var image: String {
        guard categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else {
            return "questionmark"
        }

        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .inBed:
            return "bed.double.fill"
        case .asleepCore, .asleepUnspecified:
            return "moon.fill"
        case .asleepDeep:
            return "moon.zzz.fill"
        case .asleepREM:
            return "brain.head.profile"
        case .awake:
            return "sun.max.fill"
        default:
            return "moon.fill"
        }
    }

    public var type: TimelineEntryType {
        .sleep
    }
}