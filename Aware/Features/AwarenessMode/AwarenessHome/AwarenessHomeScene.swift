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
                    VStack(alignment: .leading, spacing: 0) {
                        AwarenessHeader(summary: summary)
                            .padding(.bottom, 28)

                        TimelineSection(
                            summary: summary,
                            selectedSegmentID: selectedSegment.id,
                            onSelectSegment: selectSegment
                        )
                        .padding(.bottom, 20)

                        TimelineDetailSection(segment: selectedSegment)
                            .padding(.bottom, 28)

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
            ?? summary.timelineSegments.first(where: \.isUnclaimed)
            ?? AwarenessTimelineSegment(
                id: AwarenessTimelineSegment.unclaimedID,
                title: AwarenessTimelineSegment.unclaimedTitle,
                duration: 0,
                color: .gray,
                startDate: nil,
                endDate: nil
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
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
    
private struct TimelineSection: View {
    let summary: AwarenessTimeSummary
    let selectedSegmentID: String
    let onSelectSegment: (AwarenessTimelineSegment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AwarenessTimelineBar(
                segments: summary.timelineSegments,
                selectedSegmentID: selectedSegmentID,
                dayProgress: summary.dayProgress,
                onSelectSegment: onSelectSegment
            )
        }
    }
}

private struct TimelineDetailSection: View {
    let segment: AwarenessTimelineSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(segment.duration.awarenessDurationLabel) \(detailTitle)")
                .font(.title2.bold())
                .monospacedDigit()
                .contentTransition(.numericText(value: segment.duration))
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text("\(segment.dayProgress, format: .percent.precision(.fractionLength(0))) of today")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: segment.dayProgress))

            if let segmentTimeRangeText {
                Text(segmentTimeRangeText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: segment.dayProgress))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth, value: segment.id)
        .animation(.smooth, value: segment.duration)
        .animation(.smooth, value: segment.dayProgress)
    }

    private var detailTitle: String {
        segment.isUnclaimed ? "unclaimed" : segment.title.lowercased()
    }

    private var segmentTimeRangeText: String? {
        guard let startDate = segment.startDate, let endDate = segment.endDate else {
            return nil
        }

        return "From \(Self.timeFormatter.string(from: startDate)) to \(Self.timeFormatter.string(from: endDate))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct AwarenessTimelineBar: View {
    let segments: [AwarenessTimelineSegment]
    let selectedSegmentID: String
    let dayProgress: Double
    let onSelectSegment: (AwarenessTimelineSegment) -> Void

    private let minimumSegmentWidth: CGFloat = 16
    private let segmentSpacing: CGFloat = 2
    private let nowIndicatorWidth: CGFloat = 2
    private let nowIndicatorExtraHeight: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let totalSpacing = CGFloat(max(segments.count - 1, 0)) * segmentSpacing
            let availableWidth = max(0, width - totalSpacing)
            let segmentWidths = visibleSegmentWidths(totalWidth: availableWidth)
            let offsets = segmentWidths.reduce(into: [CGFloat]()) { partialResult, segmentWidth in
                partialResult.append((partialResult.last ?? 0) + segmentWidth + segmentSpacing)
            }
            let progressOffset = max(0, min(width, width * dayProgress))
            let claimedEndOffset: CGFloat = {
                guard let lastWidth = segmentWidths.last else { return 0 }
                let lastIndex = segmentWidths.count - 1
                let lastOffset = lastIndex == 0 ? 0 : offsets[lastIndex - 1]
                return min(width, lastOffset + lastWidth)
            }()
            let rawRemainingStartOffset = max(progressOffset, claimedEndOffset)
            let remainingStartOffset = min(
                width,
                rawRemainingStartOffset + (rawRemainingStartOffset < width ? segmentSpacing : 0)
            )
            let remainingWidth = max(0, width - remainingStartOffset)

            ZStack(alignment: .leading) {
                if remainingWidth > 0 {
                    TimelineRemainingPlaceholder()
                        .frame(width: remainingWidth, height: proxy.size.height)
                        .offset(x: remainingStartOffset)
                        .allowsHitTesting(false)
                }

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let offset = index == 0 ? 0 : offsets[index - 1]

                    Button {
                        onSelectSegment(segment)
                    } label: {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(segment.color.gradient)
                            .opacity(segment.id == selectedSegmentID ? 1 : 0.72)
                    }
                    .buttonStyle(.plain)
                    .frame(width: segmentWidths[index], height: proxy.size.height)
                    .offset(x: offset)
                    .accessibilityLabel(segment.title)
                    .accessibilityValue(segment.duration.awarenessDurationLabel)
                }

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(.red.opacity(0.4))
                    .frame(width: nowIndicatorWidth, height: proxy.size.height + nowIndicatorExtraHeight)
                    .shadow(color: .red.opacity(0.35), radius: 6, x: 0, y: 0)
                    .position(x: remainingStartOffset, y: proxy.size.height / 2)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 64)
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

private struct TimelineRemainingPlaceholder: View {
    private let cornerRadius: CGFloat = 8
    private let stripeSpacing: CGFloat = 10
    private let stripeWidth: CGFloat = 3

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height

                    Path { path in
                        var startX: CGFloat = -height
                        while startX <= width + height {
                            path.move(to: CGPoint(x: startX, y: height))
                            path.addLine(to: CGPoint(x: startX + height, y: 0))
                            startX += stripeSpacing
                        }
                    }
                    .stroke(
                        Color.mint.opacity(0.55),
                        style: StrokeStyle(lineWidth: stripeWidth, lineCap: .round)
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

#Preview {
    AwarenessHomeScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
