//
//  ClaimTimeStore.swift
//  Aware
//
//  Created by Codex on 4/30/26.
//

import Foundation
import Observation
import AwareData

@Observable
final class ClaimTimeStore {
    let intervalStart: Date
    let intervalEnd: Date

    private(set) var tags: [Tag] = []
    private(set) var drafts: [ClaimTimeDraft] = []
    var selectedDraftID: UUID?

    private var storage: Storage?

    private let defaultDraftDuration: TimeInterval = 30 * 60
    let minimumDraftDuration: TimeInterval = 5 * 60

    init(segment: AwarenessTimelineSegment) {
        let fallbackEnd = Date()
        let fallbackStart = fallbackEnd.addingTimeInterval(-max(segment.duration, 0))
        intervalStart = segment.startDate ?? fallbackStart
        intervalEnd = segment.endDate ?? fallbackEnd
    }

    var duration: TimeInterval {
        max(0, intervalEnd.timeIntervalSince(intervalStart))
    }

    var timelineSegments: [ClaimTimeTimelineSegment] {
        ClaimTimeProcessor.timelineSegments(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            drafts: drafts
        )
    }

    var gaps: [ClaimTimeGap] {
        ClaimTimeProcessor.gaps(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            drafts: drafts
        )
    }

    var claimedDuration: TimeInterval {
        drafts.reduce(0) { $0 + $1.duration }
    }

    var unclaimedDuration: TimeInterval {
        max(0, duration - claimedDuration)
    }

    var canSave: Bool {
        drafts.contains { $0.duration >= minimumDraftDuration }
    }

    var selectedDraft: ClaimTimeDraft? {
        guard let selectedDraftID else { return nil }
        return drafts.first { $0.id == selectedDraftID }
    }

    func startDate(for draftID: UUID) -> Date {
        drafts.first { $0.id == draftID }?.startDate ?? intervalStart
    }

    func endDate(for draftID: UUID) -> Date {
        drafts.first { $0.id == draftID }?.endDate ?? intervalEnd
    }

    func configure(storage: Storage) {
        self.storage = storage
        tags = storage.fetchTags()
    }

    func addDraft(for tag: Tag) {
        guard let gap = gaps.max(by: { $0.duration < $1.duration }), gap.duration >= minimumDraftDuration else {
            return
        }

        let draftDuration = min(defaultDraftDuration, gap.duration)
        let draft = ClaimTimeDraft(
            tag: tag,
            startDate: gap.startDate,
            endDate: gap.startDate.addingTimeInterval(draftDuration)
        )

        drafts.append(draft)
        selectedDraftID = draft.id
    }

    func selectDraft(_ draftID: UUID?) {
        selectedDraftID = draftID
    }

    func removeSelectedDraft() {
        guard let selectedDraftID else { return }
        drafts.removeAll { $0.id == selectedDraftID }
        self.selectedDraftID = drafts.last?.id
    }

    func updateStartDate(_ startDate: Date, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }
        let bounds = editBounds(for: draftID)
        let latestStart = drafts[index].endDate.addingTimeInterval(-minimumDraftDuration)
        drafts[index].startDate = min(max(startDate, bounds.lower), latestStart)
    }

    func updateEndDate(_ endDate: Date, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }
        let bounds = editBounds(for: draftID)
        let earliestEnd = drafts[index].startDate.addingTimeInterval(minimumDraftDuration)
        drafts[index].endDate = max(min(endDate, bounds.upper), earliestEnd)
    }

    func startDateRange(for draftID: UUID) -> ClosedRange<Date> {
        guard let draft = drafts.first(where: { $0.id == draftID }) else {
            return intervalStart...intervalEnd
        }

        let bounds = editBounds(for: draftID)
        let latestStart = draft.endDate.addingTimeInterval(-minimumDraftDuration)
        return bounds.lower...max(bounds.lower, latestStart)
    }

    func endDateRange(for draftID: UUID) -> ClosedRange<Date> {
        guard let draft = drafts.first(where: { $0.id == draftID }) else {
            return intervalStart...intervalEnd
        }

        let bounds = editBounds(for: draftID)
        let earliestEnd = draft.startDate.addingTimeInterval(minimumDraftDuration)
        return min(bounds.upper, earliestEnd)...bounds.upper
    }

    func date(at progress: Double) -> Date {
        let clampedProgress = min(max(progress, 0), 1)
        return intervalStart.addingTimeInterval(duration * clampedProgress)
    }

    func progress(for date: Date) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(date.timeIntervalSince(intervalStart) / duration, 0), 1)
    }

    func save() {
        guard let storage else { return }

        for draft in drafts where draft.duration >= minimumDraftDuration {
            let timer = Timekeeper(name: "\(draft.tag.name) Session", tags: [draft.tag])
            timer.creationDate = draft.startDate
            timer.startTime = draft.startDate
            timer.endTime = draft.endDate
            timer.totalElapsedSeconds = draft.duration
            timer.isRunning = false
            storage.insert(timer)
        }

        storage.save()
        Tracker.signal("claim_time.saved")
    }

    private func editBounds(for draftID: UUID) -> (lower: Date, upper: Date) {
        let sortedDrafts = drafts.sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }

            return lhs.endDate < rhs.endDate
        }

        guard let index = sortedDrafts.firstIndex(where: { $0.id == draftID }) else {
            return (intervalStart, intervalEnd)
        }

        let lower = index > 0 ? sortedDrafts[index - 1].endDate : intervalStart
        let upper = index < sortedDrafts.count - 1 ? sortedDrafts[index + 1].startDate : intervalEnd

        return (lower, upper)
    }
}
