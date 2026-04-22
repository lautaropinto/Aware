//
//  AwarenessHomeScene.swift
//  Aware
//
//  Created by Codex on 4/22/26.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI

struct AwarenessHomeScene: View {
    @Environment(Storage.self) private var storage
    @State private var store = AwarenessHomeStore()
    @State private var isSettingsPresented = false
    @State private var selectedSegmentID = AwarenessTimelineSegment.unclaimedID

    @Namespace private var settingsTransition

    var body: some View {
        NavigationView {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let summary = store.summary(at: context.date)
                let selectedSegment = selectedSegment(in: summary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        AwarenessHeader(summary: summary)

                        TimelineCard(
                            summary: summary,
                            selectedSegmentID: selectedSegment.id,
                            onSelectSegment: selectSegment
                        )

                        TimelineDetailCard(segment: selectedSegment)

                        if let errorMessage = store.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                }
                .scrollBounceBehavior(.basedOnSize)
                .refreshable {
                    store.refreshData(for: context.date)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton(isSettingsPresented: self.$isSettingsPresented, transition: settingsTransition)
                }
                .matchedTransitionSource(id: "settings", in: settingsTransition)
            }
            .applyBackgroundGradient()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsButton.SettingsScene()
                .navigationTransition(.zoom(sourceID: "settings", in: settingsTransition))
        }
        .onAppear {
            store.configure(storage: storage, healthKitManager: HealthKitManager.shared)
            store.refreshData()
            Tracker.signal("awareness_mode.home_viewed")
        }
        .onChange(of: storage.changeToken) {
            store.refreshData()
        }
        .environment(store)
    }

    private func selectSegment(_ segment: AwarenessTimelineSegment) {
        selectedSegmentID = segment.id
    }

    private func selectedSegment(in summary: AwarenessTimeSummary) -> AwarenessTimelineSegment {
        summary.timelineSegments.first { $0.id == selectedSegmentID }
            ?? summary.timelineSegments.first { $0.id == AwarenessTimelineSegment.unclaimedID }
            ?? AwarenessTimelineSegment(
                id: AwarenessTimelineSegment.unclaimedID,
                title: "Unclaimed",
                duration: 0,
                color: .gray
            )
    }
}

private struct AwarenessHeader: View {
    let summary: AwarenessTimeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Awareness Mode")
                .font(.largeTitle.bold())

            Text("Today is \(summary.dayProgress, format: .percent.precision(.fractionLength(0))) complete · \(summary.timeLeftToday.awarenessDurationLabel) left today")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .rounded()
    }
}
    
private struct TimelineCard: View {
    let summary: AwarenessTimeSummary
    let selectedSegmentID: String
    let onSelectSegment: (AwarenessTimelineSegment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Timeline")
                .font(.headline)

            AwarenessTimelineBar(
                segments: summary.timelineSegments,
                selectedSegmentID: selectedSegmentID,
                dayProgress: summary.dayProgress,
                onSelectSegment: onSelectSegment
            )

            HStack {
                ForEach(summary.timelineSegments) { segment in
                    AwarenessTimelineLegendItem(
                        title: segment.title,
                        color: segment.color,
                        isSelected: segment.id == selectedSegmentID
                    )
                }
                Spacer()
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AwarenessTimelineLegendItem: View {
    let title: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .rounded()
    }
}

private struct TimelineDetailCard: View {
    let segment: AwarenessTimelineSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(segment.color)
                    .frame(width: 12, height: 12)

                Text("Detail")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Text(segment.duration.awarenessDurationLabel)
                    .contentTransition(.numericText(value: segment.duration))

                Text(detailTitle)
            }
            .font(.title2.bold())
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .animation(.smooth, value: segment.duration)

            Text("\(segment.dayProgress, format: .percent.precision(.fractionLength(0))) of today")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: segment.dayProgress))
                .animation(.smooth, value: segment.dayProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var detailTitle: String {
        segment.id == AwarenessTimelineSegment.unclaimedID ? "unclaimed" : segment.title
    }
}

private struct AwarenessTimelineBar: View {
    let segments: [AwarenessTimelineSegment]
    let selectedSegmentID: String
    let dayProgress: Double
    let onSelectSegment: (AwarenessTimelineSegment) -> Void

    private let minimumSegmentWidth: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let segmentWidths = visibleSegmentWidths(totalWidth: width)
            let offsets = segmentWidths.reduce(into: [CGFloat]()) { partialResult, segmentWidth in
                partialResult.append((partialResult.last ?? 0) + segmentWidth)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.secondary.opacity(0.18))
                    .allowsHitTesting(false)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let offset = index == 0 ? 0 : offsets[index - 1]

                    Button {
                        onSelectSegment(segment)
                    } label: {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(segment.color.gradient)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(.primary.opacity(segment.id == selectedSegmentID ? 0.3 : 0), lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(width: segmentWidths[index], height: proxy.size.height)
                    .offset(x: offset)
                    .accessibilityLabel(segment.title)
                    .accessibilityValue(segment.duration.awarenessDurationLabel)
                }

                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(.primary.opacity(0.45))
                    .frame(width: 2, height: proxy.size.height)
                    .offset(x: max(0, min(width - 2, width * dayProgress)))
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func visibleSegmentWidths(totalWidth: CGFloat) -> [CGFloat] {
        let rawWidths: [CGFloat] = segments.map { max(0, totalWidth * CGFloat($0.dayProgress)) }
        let nonzeroIndexes = rawWidths.indices.filter { rawWidths[$0] > 0 }
        let minimumTotalWidth = CGFloat(nonzeroIndexes.count) * minimumSegmentWidth

        guard minimumTotalWidth <= totalWidth else {
            return rawWidths
        }

        let claimedRawWidth = rawWidths.reduce(0, +)
        let extraWidth = min(totalWidth, claimedRawWidth) - minimumTotalWidth

        guard extraWidth > 0, claimedRawWidth > 0 else {
            return rawWidths.enumerated().map { index, width in
                nonzeroIndexes.contains(index) ? minimumSegmentWidth : width
            }
        }

        return rawWidths.enumerated().map { index, width in
            guard nonzeroIndexes.contains(index) else { return width }

            return minimumSegmentWidth + (width / claimedRawWidth) * extraWidth
        }
    }
}

#Preview {
    AwarenessHomeScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
