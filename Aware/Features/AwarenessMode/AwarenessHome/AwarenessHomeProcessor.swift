//
//  AwarenessHomeProcessor.swift
//  Aware
//
//  Created by Codex on 4/22/26.
//

import Foundation
import AwareData
import HealthKit
import SwiftUI

struct AwarenessTimelineSegment: Identifiable {
    static let unclaimedID = "unclaimed"

    let id: String
    let title: String
    let duration: TimeInterval
    let color: Color

    var dayProgress: Double = 0
}

struct AwarenessTimeSummary {
    let dayStart: Date
    let dayEnd: Date
    let now: Date
    let claimedTime: TimeInterval
    let unclaimedTime: TimeInterval
    let timeLeftToday: TimeInterval
    let categorySegments: [AwarenessTimelineSegment]

    var elapsedToday: TimeInterval {
        now.timeIntervalSince(dayStart)
    }

    var dayDuration: TimeInterval {
        dayEnd.timeIntervalSince(dayStart)
    }

    var dayProgress: Double {
        guard dayDuration > 0 else { return 0 }
        return min(max(elapsedToday / dayDuration, 0), 1)
    }

    var unclaimedProgress: Double {
        guard elapsedToday > 0 else { return 0 }
        return min(max(unclaimedTime / elapsedToday, 0), 1)
    }

    var claimedProgress: Double {
        guard elapsedToday > 0 else { return 0 }
        return min(max(claimedTime / elapsedToday, 0), 1)
    }

    var unclaimedDayProgress: Double {
        guard dayDuration > 0 else { return 0 }
        return min(max(unclaimedTime / dayDuration, 0), 1)
    }

    var claimedDayProgress: Double {
        guard dayDuration > 0 else { return 0 }
        return min(max(claimedTime / dayDuration, 0), 1)
    }

    var timelineSegments: [AwarenessTimelineSegment] {
        let unclaimedSegment = AwarenessTimelineSegment(
            id: AwarenessTimelineSegment.unclaimedID,
            title: "Unclaimed",
            duration: unclaimedTime,
            color: .gray,
            dayProgress: unclaimedDayProgress
        )

        return categorySegments + [unclaimedSegment]
    }
}

enum AwarenessHomeProcessor {
    static func summary(
        now: Date = .now,
        timers: [Timekeeper],
        sleepData: [HKCategorySample],
        workoutData: [HKWorkout],
        calendar: Calendar = .current
    ) -> AwarenessTimeSummary {
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let dayRange = DateInterval(start: dayStart, end: dayEnd)
        let elapsedToday = max(0, now.timeIntervalSince(dayStart))
        let timeLeftToday = max(0, dayEnd.timeIntervalSince(now))

        let tagSegments = timerSegments(from: timers, in: dayRange, now: now, calendar: calendar)
        let timerTime = tagSegments.reduce(0) { $0 + $1.duration }

        let sleepTime = sleepData.reduce(0) { partialResult, sample in
            partialResult + overlapDuration(start: sample.startDate, end: sample.endDate, in: dayRange, now: now)
        }

        let workoutTime = workoutData.reduce(0) { partialResult, workout in
            partialResult + overlapDuration(start: workout.startDate, end: workout.endDate, in: dayRange, now: now)
        }

        let claimedTime = min(max(0, timerTime + sleepTime + workoutTime), elapsedToday)
        let unclaimedTime = max(0, elapsedToday - claimedTime)
        let categorySegments = segmentDayProgress(
            tagSegments
            + healthSegment(id: "sleep", title: "Sleep", duration: sleepTime, color: Color(hex: .sleepColor) ?? .blue)
            + healthSegment(id: "workouts", title: "Workouts", duration: workoutTime, color: Color(hex: .workoutColor) ?? .orange),
            dayDuration: dayEnd.timeIntervalSince(dayStart)
        )

        return AwarenessTimeSummary(
            dayStart: dayStart,
            dayEnd: dayEnd,
            now: now,
            claimedTime: claimedTime,
            unclaimedTime: unclaimedTime,
            timeLeftToday: timeLeftToday,
            categorySegments: categorySegments
        )
    }

    private static func timerSegments(
        from timers: [Timekeeper],
        in dayRange: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> [AwarenessTimelineSegment] {
        var tagData: [UUID: (tag: Tag, duration: TimeInterval)] = [:]

        for timer in timers {
            guard let tag = timer.mainTag else { continue }
            let duration = timerClaimedTime(timer, in: dayRange, now: now, calendar: calendar)
            guard duration > 0 else { continue }

            if let existing = tagData[tag.id] {
                tagData[tag.id] = (tag: existing.tag, duration: existing.duration + duration)
            } else {
                tagData[tag.id] = (tag: tag, duration: duration)
            }
        }

        return tagData.values
            .sorted { $0.tag.displayOrder < $1.tag.displayOrder }
            .map { tag, duration in
                AwarenessTimelineSegment(
                    id: tag.id.uuidString,
                    title: tag.name,
                    duration: duration,
                    color: tag.swiftUIColor
                )
            }
    }

    private static func healthSegment(
        id: String,
        title: String,
        duration: TimeInterval,
        color: Color
    ) -> [AwarenessTimelineSegment] {
        guard duration > 0 else { return [] }

        return [
            AwarenessTimelineSegment(
                id: id,
                title: title,
                duration: duration,
                color: color
            )
        ]
    }

    private static func segmentDayProgress(
        _ segments: [AwarenessTimelineSegment],
        dayDuration: TimeInterval
    ) -> [AwarenessTimelineSegment] {
        guard dayDuration > 0 else { return segments }

        return segments.map { segment in
            AwarenessTimelineSegment(
                id: segment.id,
                title: segment.title,
                duration: segment.duration,
                color: segment.color,
                dayProgress: min(max(segment.duration / dayDuration, 0), 1)
            )
        }
    }

    private static func timerClaimedTime(
        _ timer: Timekeeper,
        in dayRange: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> TimeInterval {
        if timer.isRunning, let startTime = timer.startTime {
            let previousTimeToday = calendar.isDate(timer.creationDate, inSameDayAs: dayRange.start)
                ? timer.totalElapsedSeconds
                : 0
            return previousTimeToday + overlapDuration(start: startTime, end: now, in: dayRange, now: now)
        }

        if let endTime = timer.endTime {
            let estimatedStart = endTime.addingTimeInterval(-timer.totalElapsedSeconds)
            return overlapDuration(start: estimatedStart, end: endTime, in: dayRange, now: now)
        }

        guard calendar.isDate(timer.creationDate, inSameDayAs: dayRange.start) else { return 0 }
        return max(0, timer.totalElapsedSeconds)
    }

    private static func overlapDuration(
        start: Date,
        end: Date,
        in dayRange: DateInterval,
        now: Date
    ) -> TimeInterval {
        let clampedStart = max(start, dayRange.start)
        let clampedEnd = min(min(end, dayRange.end), now)
        return max(0, clampedEnd.timeIntervalSince(clampedStart))
    }
}

extension TimeInterval {
    var awarenessDurationLabel: String {
        let totalMinutes = max(0, Int((self / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        switch (hours, minutes) {
        case (0, 0):
            return "0m"
        case (0, let minutes):
            return "\(minutes)m"
        case (let hours, 0):
            return "\(hours)h"
        default:
            return "\(hours)h \(minutes)m"
        }
    }

}
