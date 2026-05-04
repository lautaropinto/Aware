//
//  ClaimTimeProcessor.swift
//  Aware
//
//  Created by Codex on 4/30/26.
//

import Foundation
import SwiftUI
import AwareData

struct ClaimTimeDraft: Identifiable {
    let id: UUID
    var tag: Tag?
    var activityName: String
    var startDate: Date
    var endDate: Date
    var color: Color
    var iconName: String

    init(
        id: UUID = UUID(),
        tag: Tag? = nil,
        activityName: String = "",
        startDate: Date,
        endDate: Date,
        color: Color = .accent,
        iconName: String = "placeholder"
    ) {
        self.id = id
        self.tag = tag
        self.activityName = activityName
        self.startDate = startDate
        self.endDate = endDate
        self.color = color
        self.iconName = iconName
    }

    var trimmedActivityName: String {
        activityName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasActivity: Bool {
        !trimmedActivityName.isEmpty
    }

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
}

struct ClaimTimeTimelineSegment: Identifiable {
    let id: String
    let title: String
    let color: Color
    let iconName: String
    let startDate: Date
    let endDate: Date
    let draftID: UUID?

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }

    var isUnclaimed: Bool {
        draftID == nil
    }
}

struct ClaimTimeGap: Identifiable {
    let startDate: Date
    let endDate: Date

    var id: String {
        "\(startDate.timeIntervalSince1970)-\(endDate.timeIntervalSince1970)"
    }

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
}

enum ClaimTimeProcessor {
    static func timelineSegments(
        intervalStart: Date,
        intervalEnd: Date,
        drafts: [ClaimTimeDraft]
    ) -> [ClaimTimeTimelineSegment] {
        let intervalStart = intervalStart.startOfMinute
        let intervalEnd = intervalEnd.startOfMinute
        guard intervalEnd > intervalStart else { return [] }

        let sortedDrafts = drafts
            .filter(\.hasActivity)
            .map { draft in
                ClaimTimeDraft(
                    id: draft.id,
                    tag: draft.tag,
                    activityName: draft.activityName,
                    startDate: min(max(draft.startDate.startOfMinute, intervalStart), intervalEnd),
                    endDate: min(max(draft.endDate.startOfMinute, intervalStart), intervalEnd),
                    color: draft.color,
                    iconName: draft.iconName
                )
            }
            .filter { $0.endDate > $0.startDate }
            .sorted { lhs, rhs in
                if lhs.startDate != rhs.startDate {
                    return lhs.startDate < rhs.startDate
                }

                return lhs.endDate < rhs.endDate
            }

        var cursor = intervalStart
        var segments: [ClaimTimeTimelineSegment] = []

        for draft in sortedDrafts {
            guard draft.endDate > cursor else { continue }

            if draft.startDate > cursor {
                segments.append(
                    unclaimedSegment(startDate: cursor, endDate: draft.startDate)
                )
            }

            let claimedStart = max(draft.startDate, cursor)
            let claimedEnd = min(draft.endDate, intervalEnd)
            guard claimedEnd > claimedStart else { continue }

            segments.append(
                ClaimTimeTimelineSegment(
                    id: draft.id.uuidString,
                    title: draft.trimmedActivityName,
                    color: draft.color,
                    iconName: draft.iconName,
                    startDate: claimedStart,
                    endDate: claimedEnd,
                    draftID: draft.id
                )
            )

            cursor = claimedEnd
        }

        if cursor < intervalEnd {
            segments.append(
                unclaimedSegment(startDate: cursor, endDate: intervalEnd)
            )
        }

        return segments
    }

    static func gaps(
        intervalStart: Date,
        intervalEnd: Date,
        drafts: [ClaimTimeDraft]
    ) -> [ClaimTimeGap] {
        timelineSegments(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            drafts: drafts
        )
        .filter(\.isUnclaimed)
        .map { segment in
            ClaimTimeGap(startDate: segment.startDate, endDate: segment.endDate)
        }
    }

    private static func unclaimedSegment(startDate: Date, endDate: Date) -> ClaimTimeTimelineSegment {
        ClaimTimeTimelineSegment(
            id: "unclaimed-\(Int(startDate.timeIntervalSince1970))",
            title: "Unclaimed",
            color: .gray,
            iconName: "questionmark",
            startDate: startDate,
            endDate: endDate,
            draftID: nil
        )
    }
}
