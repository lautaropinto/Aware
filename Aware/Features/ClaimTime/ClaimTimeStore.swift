//
//  ClaimTimeStore.swift
//  Aware
//
//  Created by Codex on 4/30/26.
//

import Foundation
import Observation
import SwiftUI
import AwareData

enum ClaimTimeFormField: Equatable {
    case activity(UUID)
    case start(UUID)
    case end(UUID)

    var draftID: UUID {
        switch self {
        case .activity(let id), .start(let id), .end(let id):
            return id
        }
    }

    var isTimeField: Bool {
        switch self {
        case .activity:
            return false
        case .start, .end:
            return true
        }
    }
}

struct ClaimTimeTimeSuggestion: Identifiable {
    let id = UUID()
    let label: String
    let date: Date
}

@Observable
final class ClaimTimeStore {
    let intervalStart: Date
    let intervalEnd: Date

    private(set) var tags: [Tag] = []
    private(set) var drafts: [ClaimTimeDraft] = []
    var activeField: ClaimTimeFormField?

    private var storage: Storage?

    let minimumDraftDuration: TimeInterval = 5 * 60

    var minimumClaimDuration: TimeInterval {
        let roundedDuration = floor(duration / timeStep) * timeStep
        return max(1, min(minimumDraftDuration, roundedDuration > 0 ? roundedDuration : duration))
    }

    var canAddDraft: Bool {
        gaps.contains { $0.duration >= minimumClaimDuration }
    }

    init(segment: AwarenessTimelineSegment) {
        let fallbackEnd = Date()
        let fallbackStart = fallbackEnd.addingTimeInterval(-max(segment.duration, 0))
        intervalStart = segment.startDate ?? fallbackStart
        intervalEnd = segment.endDate ?? fallbackEnd
    }

    var duration: TimeInterval {
        max(0, intervalEnd.timeIntervalSince(intervalStart))
    }

    var formDrafts: [ClaimTimeDraft] {
        drafts.sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }

            return lhs.endDate < rhs.endDate
        }
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
        drafts
            .filter(\.hasActivity)
            .reduce(0) { $0 + $1.duration }
    }

    var unclaimedDuration: TimeInterval {
        max(0, duration - claimedDuration)
    }

    var canSave: Bool {
        drafts.contains { $0.hasActivity && $0.duration >= minimumClaimDuration }
    }

    func configure(storage: Storage) {
        self.storage = storage
        tags = storage.fetchTags()

        if drafts.isEmpty {
            addDraft()
        }
    }

    @discardableResult
    func addDraft() -> UUID? {
        if let emptyDraft = formDrafts.first(where: { !$0.hasActivity }) {
            activeField = .activity(emptyDraft.id)
            return emptyDraft.id
        }

        guard let gap = gaps.first(where: { $0.duration >= minimumClaimDuration }) else {
            return nil
        }

        let draftStart = max(gap.startDate, ceilToStep(gap.startDate))
        let draftDuration = preferredDraftDuration(for: gap.endDate.timeIntervalSince(draftStart))
        let draftEnd = min(
            gap.endDate,
            draftDuration < timeStep ? gap.endDate : floorToStep(draftStart.addingTimeInterval(draftDuration))
        )
        guard draftEnd.timeIntervalSince(draftStart) >= minimumClaimDuration else { return nil }

        let draft = ClaimTimeDraft(
            startDate: draftStart,
            endDate: draftEnd
        )

        drafts.append(draft)
        activeField = .activity(draft.id)
        return draft.id
    }

    func removeDraft(_ draftID: UUID) {
        drafts.removeAll { $0.id == draftID }

        if activeField?.draftID == draftID {
            activeField = drafts.first.map { .activity($0.id) }
        }

        if drafts.isEmpty {
            _ = addDraft()
        }
    }

    func activityName(for draftID: UUID) -> String {
        drafts.first { $0.id == draftID }?.activityName ?? ""
    }

    func updateActivityName(_ activityName: String, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }

        let trimmedName = activityName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let tag = exactTagMatch(for: trimmedName) {
            applyTag(tag, to: index)
        } else {
            drafts[index].tag = nil
            drafts[index].activityName = activityName
            drafts[index].color = .accent
            drafts[index].iconName = "placeholder"
        }
    }

    func selectActivity(_ tag: Tag, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }
        applyTag(tag, to: index)
        activeField = .start(draftID)
    }

    func acceptTypedActivity(for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }

        if drafts[index].hasActivity {
            drafts[index].activityName = drafts[index].trimmedActivityName
        }
        activeField = .start(draftID)
    }

    func advance(from field: ClaimTimeFormField) {
        switch field {
        case .activity(let draftID):
            acceptTypedActivity(for: draftID)
        case .start(let draftID):
            activeField = .end(draftID)
        case .end:
            activeField = nil
        }
    }

    func retreat(from field: ClaimTimeFormField) {
        switch field {
        case .activity:
            activeField = nil
        case .start(let draftID):
            activeField = .activity(draftID)
        case .end(let draftID):
            activeField = .start(draftID)
        }
    }

    func activitySuggestions(for draftID: UUID) -> [Tag] {
        let query = normalizeActivityName(activityName(for: draftID))

        if query.isEmpty {
            return Array(tags.prefix(8))
        }

        return tags
            .filter { normalizeActivityName($0.name).contains(query) }
            .prefix(8)
            .map { $0 }
    }

    func startDate(for draftID: UUID) -> Date {
        drafts.first { $0.id == draftID }?.startDate ?? intervalStart
    }

    func endDate(for draftID: UUID) -> Date {
        drafts.first { $0.id == draftID }?.endDate ?? intervalEnd
    }

    func updateStartDate(_ startDate: Date, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }
        let roundedStartDate = roundToStep(startDate)
        let bounds = editBounds(for: draftID)
        let latestStart = drafts[index].endDate.addingTimeInterval(-minimumClaimDuration)
        drafts[index].startDate = min(max(roundedStartDate, bounds.lower), latestStart)
    }

    func updateEndDate(_ endDate: Date, for draftID: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == draftID }) else { return }
        let roundedEndDate = roundToStep(endDate)
        let bounds = editBounds(for: draftID)
        let earliestEnd = drafts[index].startDate.addingTimeInterval(minimumClaimDuration)
        drafts[index].endDate = max(min(roundedEndDate, bounds.upper), earliestEnd)
    }

    func timeSuggestions(for field: ClaimTimeFormField) -> [ClaimTimeTimeSuggestion] {
        let draftID = field.draftID
        let bounds = selectableRange(for: field)
        let now = Date()
        let midpoint = bounds.lowerBound.addingTimeInterval(bounds.upperBound.timeIntervalSince(bounds.lowerBound) / 2)
        var candidates: [(String, Date)] = [
            ("Start", bounds.lowerBound),
            ("End", bounds.upperBound),
            ("30 minutes ago", now.addingTimeInterval(-30 * 60)),
            ("1hr ago", now.addingTimeInterval(-60 * 60)),
            (roundToStep(midpoint).formattedTime, midpoint)
        ]

        if case .end = field {
            let startDate = startDate(for: draftID)
            candidates.append(("30 minutes later", startDate.addingTimeInterval(30 * 60)))
            candidates.append(("1hr later", startDate.addingTimeInterval(60 * 60)))
        }

        var seenDates: Set<Int> = []
        return candidates.compactMap { label, date in
            let roundedDate = roundToStep(date)
            guard bounds.contains(roundedDate) else { return nil }

            let key = Int(roundedDate.timeIntervalSince1970 / timeStep)
            guard !seenDates.contains(key) else { return nil }
            seenDates.insert(key)

            return ClaimTimeTimeSuggestion(label: label, date: roundedDate)
        }
    }

    func selectableRange(for field: ClaimTimeFormField) -> ClosedRange<Date> {
        guard let draft = drafts.first(where: { $0.id == field.draftID }) else {
            return intervalStart...intervalEnd
        }

        let bounds = editBounds(for: field.draftID)

        switch field {
        case .activity:
            return bounds.lower...bounds.upper
        case .start:
            let upper = max(bounds.lower, draft.endDate.addingTimeInterval(-minimumClaimDuration))
            return bounds.lower...upper
        case .end:
            let lower = min(bounds.upper, draft.startDate.addingTimeInterval(minimumClaimDuration))
            return lower...bounds.upper
        }
    }

    func timeTicks(for field: ClaimTimeFormField) -> [Date] {
        let range = selectableRange(for: field)
        var ticks: [Date] = []

        appendUnique(range.lowerBound, to: &ticks)

        let firstTick = ceilToStep(range.lowerBound)
        let lastTick = floorToStep(range.upperBound)

        if firstTick <= lastTick {
            var tick = firstTick
            while tick <= lastTick {
                appendUnique(tick, to: &ticks)
                tick = tick.addingTimeInterval(timeStep)
            }
        }

        appendUnique(range.upperBound, to: &ticks)

        switch field {
        case .activity:
            break
        case .start(let draftID):
            appendUnique(startDate(for: draftID), to: &ticks)
        case .end(let draftID):
            appendUnique(endDate(for: draftID), to: &ticks)
        }

        return ticks.sorted()
    }

    func progress(for date: Date) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(date.timeIntervalSince(intervalStart) / duration, 0), 1)
    }

    func save() {
        guard let storage else { return }

        var knownTagsByName: [String: Tag] = [:]
        for tag in tags {
            knownTagsByName[normalizeActivityName(tag.name)] = tag
        }
        var nextDisplayOrder = (tags.map(\.displayOrder).max() ?? -1) + 1

        for draft in formDrafts where draft.hasActivity && draft.duration >= minimumClaimDuration {
            let tag: Tag

            if let existingTag = draft.tag ?? knownTagsByName[normalizeActivityName(draft.trimmedActivityName)] {
                tag = existingTag
            } else {
                let newTag = Tag(
                    name: storedActivityName(from: draft.trimmedActivityName),
                    color: Color.accent.toHex(),
                    image: "placeholder",
                    displayOrder: nextDisplayOrder
                )
                nextDisplayOrder += 1
                storage.insert(newTag)
                knownTagsByName[normalizeActivityName(newTag.name)] = newTag
                tag = newTag
            }

            let timer = Timekeeper(name: "\(tag.name) Session", tags: [tag])
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

    private func applyTag(_ tag: Tag, to index: Int) {
        drafts[index].tag = tag
        drafts[index].activityName = tag.name
        drafts[index].color = tag.swiftUIColor
        drafts[index].iconName = tag.image
    }

    private func exactTagMatch(for activityName: String) -> Tag? {
        let normalizedName = normalizeActivityName(activityName)
        guard !normalizedName.isEmpty else { return nil }

        return tags.first { normalizeActivityName($0.name) == normalizedName }
    }

    private func preferredDraftDuration(for availableDuration: TimeInterval) -> TimeInterval {
        let roundedAvailableDuration = floor(availableDuration / timeStep) * timeStep

        guard roundedAvailableDuration > 0 else {
            return availableDuration
        }

        for duration in [60 * 60, 30 * 60, 15 * 60] where roundedAvailableDuration >= TimeInterval(duration) {
            return TimeInterval(duration)
        }

        return roundedAvailableDuration
    }

    private func editBounds(for draftID: UUID) -> (lower: Date, upper: Date) {
        let sortedDrafts = formDrafts
        guard let index = sortedDrafts.firstIndex(where: { $0.id == draftID }) else {
            return (intervalStart, intervalEnd)
        }

        let lower = index > 0 ? sortedDrafts[index - 1].endDate : intervalStart
        let upper = index < sortedDrafts.count - 1 ? sortedDrafts[index + 1].startDate : intervalEnd

        return (lower, upper)
    }

    private var timeStep: TimeInterval {
        duration < minimumDraftDuration ? 60 : minimumDraftDuration
    }

    private func roundToStep(_ date: Date) -> Date {
        let interval = timeStep
        let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded() * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    private func ceilToStep(_ date: Date) -> Date {
        let interval = timeStep
        let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded(.up) * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    private func floorToStep(_ date: Date) -> Date {
        let interval = timeStep
        let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded(.down) * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    private func appendUnique(_ date: Date, to dates: inout [Date]) {
        guard !dates.contains(where: { abs($0.timeIntervalSince(date)) < 0.5 }) else { return }
        dates.append(date)
    }

    private func normalizeActivityName(_ rawValue: String) -> String {
        let normalized = rawValue
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))

        return normalized
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func storedActivityName(from rawValue: String) -> String {
        let trimmedName = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstCharacter = trimmedName.first else { return trimmedName }

        return firstCharacter.uppercased() + trimmedName.dropFirst()
    }
}
