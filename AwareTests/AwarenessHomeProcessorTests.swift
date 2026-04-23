//
//  AwarenessHomeProcessorTests.swift
//  AwareTests
//
//  Created by Codex on 4/22/26.
//

import Foundation
import Testing
import AwareData
@testable import Aware

struct AwarenessHomeProcessorTests {
    @Test func unclaimedTimeSubtractsClaimedTimerTimeFromElapsedDay() {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 0))!
        let now = calendar.date(byAdding: .hour, value: 12, to: dayStart)!
        let tag = Tag(name: "Work", color: "#34C759", image: "briefcase.fill")
        let timer = Timekeeper(name: "Work Session", tags: [tag])
        timer.creationDate = calendar.date(byAdding: .hour, value: 8, to: dayStart)!
        timer.endTime = calendar.date(byAdding: .hour, value: 10, to: dayStart)!
        timer.totalElapsedSeconds = 2 * 60 * 60

        let summary = AwarenessHomeProcessor.summary(
            now: now,
            timers: [timer],
            sleepData: [],
            workoutData: [],
            calendar: calendar
        )

        #expect(summary.claimedTime == 2 * 60 * 60)
        #expect(summary.unclaimedTime == 10 * 60 * 60)
        #expect(summary.timeLeftToday == 12 * 60 * 60)
        #expect(summary.categorySegments.map(\.title) == ["Work"])
        #expect(summary.timelineSegments.map(\.title) == ["Unclaimed", "Work", "Unclaimed"])
        #expect(summary.timelineSegments.map(\.duration) == [8 * 60 * 60, 2 * 60 * 60, 2 * 60 * 60])
    }

    @Test func timersWithoutTagsStayUnclaimed() {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 0))!
        let now = calendar.date(byAdding: .hour, value: 12, to: dayStart)!
        let timer = Timekeeper(name: "Loose Session")
        timer.creationDate = calendar.date(byAdding: .hour, value: 8, to: dayStart)!
        timer.endTime = calendar.date(byAdding: .hour, value: 10, to: dayStart)!
        timer.totalElapsedSeconds = 2 * 60 * 60

        let summary = AwarenessHomeProcessor.summary(
            now: now,
            timers: [timer],
            sleepData: [],
            workoutData: [],
            calendar: calendar
        )

        #expect(summary.claimedTime == 0)
        #expect(summary.unclaimedTime == 12 * 60 * 60)
    }

    @Test func timelineIncludesSeparateUnclaimedGapsBetweenActivities() {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 22, hour: 0))!
        let now = calendar.date(byAdding: .hour, value: 12, to: dayStart)!
        let tag = Tag(name: "Work", color: "#34C759", image: "briefcase.fill")

        let firstSession = Timekeeper(name: "Morning Session", tags: [tag])
        firstSession.creationDate = calendar.date(byAdding: .hour, value: 8, to: dayStart)!
        firstSession.endTime = calendar.date(byAdding: .hour, value: 9, to: dayStart)!
        firstSession.totalElapsedSeconds = 60 * 60

        let secondSession = Timekeeper(name: "Late Morning Session", tags: [tag])
        secondSession.creationDate = calendar.date(byAdding: .hour, value: 10, to: dayStart)!
        secondSession.endTime = calendar.date(byAdding: .hour, value: 11, to: dayStart)!
        secondSession.totalElapsedSeconds = 60 * 60

        let summary = AwarenessHomeProcessor.summary(
            now: now,
            timers: [firstSession, secondSession],
            sleepData: [],
            workoutData: [],
            calendar: calendar
        )

        #expect(summary.timelineSegments.map(\.title) == ["Unclaimed", "Work", "Unclaimed", "Work", "Unclaimed"])
        #expect(summary.timelineSegments.map(\.duration) == [8 * 60 * 60, 60 * 60, 60 * 60, 60 * 60, 60 * 60])
    }
}
