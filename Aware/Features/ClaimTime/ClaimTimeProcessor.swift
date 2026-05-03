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
    let tag: Tag
    var startDate: Date
    var endDate: Date

    init(id: UUID = UUID(), tag: Tag, startDate: Date, endDate: Date) {
        self.id = id
        self.tag = tag
        self.startDate = startDate
        self.endDate = endDate
    }

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
}

struct ClaimTimeTimelineSegment: Identifiable {
    let id: String
    let title: String
    let color: Color
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
        guard intervalEnd > intervalStart else { return [] }

        let sortedDrafts = drafts
            .map { draft in
                ClaimTimeDraft(
                    id: draft.id,
                    tag: draft.tag,
                    startDate: min(max(draft.startDate, intervalStart), intervalEnd),
                    endDate: min(max(draft.endDate, intervalStart), intervalEnd)
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
                    title: draft.tag.name,
                    color: draft.tag.swiftUIColor,
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
            startDate: startDate,
            endDate: endDate,
            draftID: nil
        )
    }
}
