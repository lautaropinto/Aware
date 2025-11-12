//
//  HKWorkout+TimelineEntry.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/11/25.
//

import Foundation
import HealthKit
import SwiftUI
import AwareData

extension String {
    static let workoutColor = "#a6ff00"
}

extension HKWorkout: @retroactive TimelineEntry {
    public var id: UUID {
        UUID(uuidString: uuid.uuidString) ?? UUID()
    }

    public var name: String {
        workoutActivityType.localizedName
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

    public var swiftUIColor: Color {
        guard let color = Color(hex: .workoutColor) else {
            return .orange
        }
        return color
    }

    public var image: String {
        workoutActivityType.systemImageName
    }

    public var type: TimelineEntryType {
        .workout
    }
}

// MARK: - HKWorkoutActivityType Extensions

extension HKWorkoutActivityType {
    var localizedName: String {
        switch self {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .yoga:
            return "Yoga"
        case .dance:
            return "Dance"
        case .elliptical:
            return "Elliptical"
        case .rowing:
            return "Rowing"
        case .stairClimbing:
            return "Stair Climbing"
        case .hiking:
            return "Hiking"
        case .tennis:
            return "Tennis"
        case .basketball:
            return "Basketball"
        case .americanFootball:
            return "Football"
        case .soccer:
            return "Soccer"
        case .golf:
            return "Golf"
        case .baseball:
            return "Baseball"
        case .hockey:
            return "Hockey"
        case .volleyball:
            return "Volleyball"
        case .surfingSports:
            return "Surfing"
        case .snowSports:
            return "Snow Sports"
        case .martialArts:
            return "Martial Arts"
        case .crossTraining:
            return "Cross Training"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .traditionalStrengthTraining:
            return "Weight Lifting"
        case .coreTraining:
            return "Core Training"
        case .flexibility:
            return "Flexibility"
        case .mindAndBody:
            return "Mind & Body"
        case .pilates:
            return "Pilates"
        case .barre:
            return "Barre"
        case .kickboxing:
            return "Kickboxing"
        case .boxing:
            return "Boxing"
        case .wrestling:
            return "Wrestling"
        case .climbing:
            return "Climbing"
        case .equestrianSports:
            return "Equestrian"
        case .fishing:
            return "Fishing"
        case .hunting:
            return "Hunting"
        case .sailing:
            return "Sailing"
        case .skatingSports:
            return "Skating"
        case .paddleSports:
            return "Paddle Sports"
        case .waterSports:
            return "Water Sports"
        default:
            return "Workout"
        }
    }

    var systemImageName: String {
        switch self {
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .yoga:
            return "figure.yoga"
        case .dance:
            return "figure.dance"
        case .elliptical:
            return "figure.elliptical"
        case .rowing:
            return "figure.rowing"
        case .stairClimbing:
            return "figure.stair.stepper"
        case .hiking:
            return "figure.hiking"
        case .tennis:
            return "figure.tennis"
        case .basketball:
            return "figure.basketball"
        case .soccer:
            return "figure.soccer"
        case .golf:
            return "figure.golf"
        case .baseball:
            return "figure.baseball"
        case .hockey:
            return "figure.hockey"
        case .volleyball:
            return "figure.volleyball"
        case .surfingSports:
            return "figure.surfing"
        case .snowSports:
            return "figure.snowboarding"
        case .martialArts:
            return "figure.martial.arts"
        case .crossTraining:
            return "figure.cross.training"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .coreTraining:
            return "figure.core.training"
        case .flexibility:
            return "figure.flexibility"
        case .mindAndBody:
            return "figure.mind.and.body"
        case .pilates:
            return "figure.pilates"
        case .barre:
            return "figure.barre"
        case .kickboxing, .boxing:
            return "figure.kickboxing"
        case .wrestling:
            return "figure.wrestling"
        case .climbing:
            return "figure.climbing"
        case .equestrianSports:
            return "figure.equestrian.sports"
        case .fishing:
            return "figure.fishing"
        case .hunting:
            return "figure.hunting"
        case .sailing:
            return "sailboat"
        case .skatingSports:
            return "figure.skating"
        case .paddleSports:
            return "figure.paddleboarding"
        case .waterSports:
            return "figure.water.fitness"
        default:
            return "figure.mixed.cardio"
        }
    }
}
