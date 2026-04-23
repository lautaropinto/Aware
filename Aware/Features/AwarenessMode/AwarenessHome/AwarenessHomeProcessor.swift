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
    static let unclaimedTitle = "Unclaimed"

    let id: String
    let title: String
    let duration: TimeInterval
    let color: Color
    let startDate: Date?
    let endDate: Date?

    var dayProgress: Double = 0

    var isUnclaimed: Bool {
        id == Self.unclaimedID || id.hasPrefix("\(Self.unclaimedID)-")
    }
}

struct AwarenessTimeSummary {
    let dayStart: Date
    let dayEnd: Date
    let now: Date
    let claimedTime: TimeInterval
    let unclaimedTime: TimeInterval
    let timeLeftToday: TimeInterval
    let categorySegments: [AwarenessTimelineSegment]
    let timelineSegments: [AwarenessTimelineSegment]

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

}

private struct ClaimedInterval {
    let key: String
    let title: String
    let color: Color
    let start: Date
    let end: Date
    let priority: Int
}

private struct TimelineSlice {
    let key: String
    let title: String
    let color: Color
    let start: Date
    let end: Date
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
        let clampedNow = min(max(now, dayStart), dayEnd)
        let timeLeftToday = max(0, dayEnd.timeIntervalSince(now))
        let dayDuration = dayEnd.timeIntervalSince(dayStart)

        let tagSegments = timerSegments(from: timers, in: dayRange, now: now, calendar: calendar)
        let sleepTime = sleepData.reduce(0) { partialResult, sample in
            partialResult + overlapDuration(start: sample.startDate, end: sample.endDate, in: dayRange, now: now)
        }
        let workoutTime = workoutData.reduce(0) { partialResult, workout in
            partialResult + overlapDuration(start: workout.startDate, end: workout.endDate, in: dayRange, now: now)
        }

        let categorySegments = segmentDayProgress(
            tagSegments
            + healthSegment(id: "sleep", title: "Sleep", duration: sleepTime, color: Color(hex: .sleepColor) ?? .blue)
            + healthSegment(id: "workouts", title: "Workouts", duration: workoutTime, color: Color(hex: .workoutColor) ?? .orange),
            dayDuration: dayDuration
        )

        let claimedIntervals = claimedIntervals(
            timers: timers,
            sleepData: sleepData,
            workoutData: workoutData,
            in: dayRange,
            now: clampedNow,
            calendar: calendar
        )
        let timelineSegments = timelineSegments(
            from: claimedIntervals,
            dayStart: dayStart,
            now: clampedNow,
            dayDuration: dayDuration
        )
        let claimedTime = timelineSegments
            .filter { !$0.isUnclaimed }
            .reduce(0) { $0 + $1.duration }
        let unclaimedTime = timelineSegments
            .filter(\.isUnclaimed)
            .reduce(0) { $0 + $1.duration }

        return AwarenessTimeSummary(
            dayStart: dayStart,
            dayEnd: dayEnd,
            now: now,
            claimedTime: claimedTime,
            unclaimedTime: unclaimedTime,
            timeLeftToday: timeLeftToday,
            categorySegments: categorySegments,
            timelineSegments: timelineSegments
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
                    color: tag.swiftUIColor,
                    startDate: nil,
                    endDate: nil
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
                color: color,
                startDate: nil,
                endDate: nil
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
                startDate: segment.startDate,
                endDate: segment.endDate,
                dayProgress: min(max(segment.duration / dayDuration, 0), 1)
            )
        }
    }

    private static func claimedIntervals(
        timers: [Timekeeper],
        sleepData: [HKCategorySample],
        workoutData: [HKWorkout],
        in dayRange: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> [ClaimedInterval] {
        var intervals: [ClaimedInterval] = []

        for timer in timers {
            guard let tag = timer.mainTag else { continue }
            let timerRanges = timerClaimedIntervals(timer, in: dayRange, now: now, calendar: calendar)

            for range in timerRanges {
                intervals.append(
                    ClaimedInterval(
                        key: "timer-\(tag.id.uuidString)",
                        title: tag.name,
                        color: tag.swiftUIColor,
                        start: range.start,
                        end: range.end,
                        priority: 0
                    )
                )
            }
        }

        for sample in sleepData {
            guard let overlap = overlapInterval(
                start: sample.startDate,
                end: sample.endDate,
                in: dayRange,
                now: now
            ) else { continue }

            intervals.append(
                ClaimedInterval(
                    key: "sleep",
                    title: "Sleep",
                    color: Color(hex: .sleepColor) ?? .blue,
                    start: overlap.start,
                    end: overlap.end,
                    priority: 2
                )
            )
        }

        for workout in workoutData {
            guard let overlap = overlapInterval(
                start: workout.startDate,
                end: workout.endDate,
                in: dayRange,
                now: now
            ) else { continue }

            intervals.append(
                ClaimedInterval(
                    key: "workout-\(workout.uuid.uuidString)",
                    title: "Workout",
                    color: Color(hex: .workoutColor) ?? .orange,
                    start: overlap.start,
                    end: overlap.end,
                    priority: 1
                )
            )
        }

        return intervals
    }

    private static func timelineSegments(
        from claimedIntervals: [ClaimedInterval],
        dayStart: Date,
        now: Date,
        dayDuration: TimeInterval
    ) -> [AwarenessTimelineSegment] {
        guard dayDuration > 0, now > dayStart else { return [] }
        let elapsedRange = DateInterval(start: dayStart, end: now)

        let clampedIntervals = claimedIntervals.compactMap { interval -> ClaimedInterval? in
            guard let overlap = overlapInterval(
                start: interval.start,
                end: interval.end,
                in: elapsedRange,
                now: now
            ) else { return nil }

            return ClaimedInterval(
                key: interval.key,
                title: interval.title,
                color: interval.color,
                start: overlap.start,
                end: overlap.end,
                priority: interval.priority
            )
        }

        var boundaries = Set<Date>([elapsedRange.start, elapsedRange.end])
        for interval in clampedIntervals {
            boundaries.insert(interval.start)
            boundaries.insert(interval.end)
        }

        let sortedBoundaries = boundaries.sorted()
        guard sortedBoundaries.count >= 2 else { return [] }

        var slices: [TimelineSlice] = []

        for index in 0..<(sortedBoundaries.count - 1) {
            let sliceStart = sortedBoundaries[index]
            let sliceEnd = sortedBoundaries[index + 1]
            guard sliceEnd > sliceStart else { continue }

            let activeIntervals = clampedIntervals.filter {
                $0.start < sliceEnd && $0.end > sliceStart
            }

            if let active = activeIntervals.min(by: intervalOrdering) {
                slices.append(
                    TimelineSlice(
                        key: active.key,
                        title: active.title,
                        color: active.color,
                        start: sliceStart,
                        end: sliceEnd
                    )
                )
            } else {
                slices.append(
                    TimelineSlice(
                        key: AwarenessTimelineSegment.unclaimedID,
                        title: AwarenessTimelineSegment.unclaimedTitle,
                        color: .gray,
                        start: sliceStart,
                        end: sliceEnd
                    )
                )
            }
        }

        let mergedSlices = mergeAdjacentSlices(slices)
        var hasPrimaryUnclaimedID = false

        return mergedSlices.map { slice in
            let id: String
            if slice.key == AwarenessTimelineSegment.unclaimedID {
                if hasPrimaryUnclaimedID {
                    id = "\(AwarenessTimelineSegment.unclaimedID)-\(Int(slice.start.timeIntervalSince1970))"
                } else {
                    id = AwarenessTimelineSegment.unclaimedID
                    hasPrimaryUnclaimedID = true
                }
            } else {
                id = "\(slice.key)-\(Int(slice.start.timeIntervalSince1970))"
            }

            let duration = slice.end.timeIntervalSince(slice.start)

            return AwarenessTimelineSegment(
                id: id,
                title: slice.title,
                duration: duration,
                color: slice.color,
                startDate: slice.start,
                endDate: slice.end,
                dayProgress: min(max(duration / dayDuration, 0), 1)
            )
        }
    }

    private static func mergeAdjacentSlices(_ slices: [TimelineSlice]) -> [TimelineSlice] {
        guard var current = slices.first else { return [] }
        var merged: [TimelineSlice] = []

        for slice in slices.dropFirst() {
            if slice.key == current.key, slice.start == current.end {
                current = TimelineSlice(
                    key: current.key,
                    title: current.title,
                    color: current.color,
                    start: current.start,
                    end: slice.end
                )
            } else {
                merged.append(current)
                current = slice
            }
        }

        merged.append(current)
        return merged
    }

    private static func intervalOrdering(_ lhs: ClaimedInterval, _ rhs: ClaimedInterval) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }

        if lhs.start != rhs.start {
            return lhs.start < rhs.start
        }

        if lhs.end != rhs.end {
            return lhs.end > rhs.end
        }

        return lhs.key < rhs.key
    }

    private static func timerClaimedIntervals(
        _ timer: Timekeeper,
        in dayRange: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> [DateInterval] {
        if timer.isRunning, let startTime = timer.startTime {
            var ranges: [DateInterval] = []

            if let currentRange = overlapInterval(start: startTime, end: now, in: dayRange, now: now) {
                ranges.append(currentRange)
            }

            let previousTimeToday = calendar.isDate(timer.creationDate, inSameDayAs: dayRange.start)
                ? timer.totalElapsedSeconds
                : 0

            if previousTimeToday > 0 {
                let previousEnd = min(startTime, now)
                let previousStart = previousEnd.addingTimeInterval(-previousTimeToday)
                if let previousRange = overlapInterval(start: previousStart, end: previousEnd, in: dayRange, now: now) {
                    ranges.append(previousRange)
                }
            }

            return ranges
        }

        if let endTime = timer.endTime {
            let estimatedStart = endTime.addingTimeInterval(-timer.totalElapsedSeconds)
            guard let overlap = overlapInterval(start: estimatedStart, end: endTime, in: dayRange, now: now) else {
                return []
            }
            return [overlap]
        }

        guard calendar.isDate(timer.creationDate, inSameDayAs: dayRange.start) else { return [] }
        guard timer.totalElapsedSeconds > 0 else { return [] }

        let estimatedEnd = now
        let estimatedStart = estimatedEnd.addingTimeInterval(-timer.totalElapsedSeconds)

        guard let overlap = overlapInterval(start: estimatedStart, end: estimatedEnd, in: dayRange, now: now) else {
            return []
        }

        return [overlap]
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

    private static func overlapInterval(
        start: Date,
        end: Date,
        in dayRange: DateInterval,
        now: Date
    ) -> DateInterval? {
        let clampedStart = max(start, dayRange.start)
        let clampedEnd = min(min(end, dayRange.end), now)
        guard clampedEnd > clampedStart else { return nil }
        return DateInterval(start: clampedStart, end: clampedEnd)
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
