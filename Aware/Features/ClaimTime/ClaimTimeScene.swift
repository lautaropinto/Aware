//
//  ClaimTimeScene.swift
//  Aware
//
//  Created by Codex on 4/30/26.
//

import SwiftUI
import AwareData

struct ClaimTimeScene: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Storage.self) private var storage
    @State private var store: ClaimTimeStore

    init(segment: AwarenessTimelineSegment) {
        _store = State(initialValue: ClaimTimeStore(segment: segment))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ClaimTimeHeader(store: store)
                    ClaimTimeTimelineEditor(store: store)
                    ClaimTimeActivityPicker(store: store)
                    ClaimTimeSelectedDraftEditor(store: store)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .scrollBounceBehavior(.basedOnSize)
            .applyBackgroundGradient(.toBottom)
            .navigationTitle("Claim Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.save()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .disabled(!store.canSave)
                }
            }
        }
        .onAppear {
            store.configure(storage: storage)
            Tracker.signal("claim_time.opened")
        }
    }
}

private struct ClaimTimeHeader: View {
    let store: ClaimTimeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What were you doing?")
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("\(store.intervalStart.formattedTime) - \(store.intervalEnd.formattedTime) · \(store.duration.awarenessDurationLabel)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ClaimTimeMetricPill(
                    title: "Claimed",
                    value: store.claimedDuration.awarenessDurationLabel,
                    color: .accent
                )

                ClaimTimeMetricPill(
                    title: "Unclaimed",
                    value: store.unclaimedDuration.awarenessDurationLabel,
                    color: .gray
                )
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ClaimTimeMetricPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.gradient)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.monospacedDigit().weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct ClaimTimeTimelineEditor: View {
    let store: ClaimTimeStore

    private let handleWidth: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { proxy in
                let width = max(1, proxy.size.width)

                ZStack(alignment: .leading) {
                    ForEach(store.timelineSegments) { segment in
                        let startProgress = store.progress(for: segment.startDate)
                        let endProgress = store.progress(for: segment.endDate)
                        let segmentX = width * startProgress
                        let segmentWidth = max(8, width * (endProgress - startProgress))

                        Button {
                            store.selectDraft(segment.draftID)
                        } label: {
                            ClaimTimeTimelineBlock(
                                segment: segment,
                                isSelected: store.selectedDraftID == segment.draftID && segment.draftID != nil
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(width: segmentWidth, height: 86)
                        .offset(x: segmentX)
                        .accessibilityLabel(segment.title)
                        .accessibilityValue(segment.duration.awarenessDurationLabel)
                    }

                    if let selectedDraft = store.selectedDraft {
                        selectedHandles(for: selectedDraft, width: width)
                    }
                }
                .frame(width: width, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(height: 86)

            HStack {
                Text(store.intervalStart.formattedTime)
                Spacer()
                Text(store.intervalEnd.formattedTime)
            }
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private func selectedHandles(for draft: ClaimTimeDraft, width: CGFloat) -> some View {
        let startX = width * store.progress(for: draft.startDate)
        let endX = width * store.progress(for: draft.endDate)

        return ZStack(alignment: .leading) {
            ClaimTimeTrimHandle(edge: .leading)
                .offset(x: max(0, startX - handleWidth / 2))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateStart(for: draft, locationX: value.location.x + startX - handleWidth / 2, width: width)
                        }
                )

            ClaimTimeTrimHandle(edge: .trailing)
                .offset(x: min(width - handleWidth, endX - handleWidth / 2))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateEnd(for: draft, locationX: value.location.x + endX - handleWidth / 2, width: width)
                        }
                )
        }
        .frame(width: width, height: 86, alignment: .leading)
    }

    private func updateStart(for draft: ClaimTimeDraft, locationX: CGFloat, width: CGFloat) {
        let progress = locationX / max(1, width)
        store.updateStartDate(store.date(at: progress), for: draft.id)
    }

    private func updateEnd(for draft: ClaimTimeDraft, locationX: CGFloat, width: CGFloat) {
        let progress = locationX / max(1, width)
        store.updateEndDate(store.date(at: progress), for: draft.id)
    }
}

private struct ClaimTimeTimelineBlock: View {
    let segment: ClaimTimeTimelineSegment
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .overlay {
                if segment.isUnclaimed {
                    ClaimTimeStripeOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(segment.color.gradient)
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(segment.title)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)

                    Text(segment.duration.awarenessDurationLabel)
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(segment.isUnclaimed ? Color.secondary : Color.white)
                .shadow(color: segment.isUnclaimed ? .clear : .black.opacity(0.18), radius: 2, y: 1)
                .padding(8)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 2)
                        .shadow(color: segment.color.opacity(0.45), radius: 12, y: 4)
                }
            }
    }
}

private struct ClaimTimeStripeOverlay: View {
    private let stripeSpacing: CGFloat = 10

    var body: some View {
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
                Color.mint.opacity(0.48),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
        }
    }
}

private struct ClaimTimeTrimHandle: View {
    enum Edge {
        case leading
        case trailing
    }

    let edge: Edge

    var body: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(.white.opacity(0.16))
            .frame(width: 26, height: 86)
            .overlay {
                Capsule()
                    .fill(.white.opacity(0.92))
                    .frame(width: 4, height: 42)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
            .accessibilityLabel(edge == .leading ? "Start time" : "End time")
    }
}

private struct ClaimTimeActivityPicker: View {
    let store: ClaimTimeStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.tags, id: \.id) { tag in
                    Button {
                        store.addDraft(for: tag)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tag.image.isEmpty ? "circle.fill" : tag.image)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(tag.swiftUIColor)

                            Text(tag.name)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.gaps.allSatisfy { $0.duration < store.minimumDraftDuration })
                }
            }
        }
    }
}

private struct ClaimTimeSelectedDraftEditor: View {
    let store: ClaimTimeStore

    var body: some View {
        if let draft = store.selectedDraft {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: draft.tag.image.isEmpty ? "circle.fill" : draft.tag.image)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(draft.tag.swiftUIColor.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(draft.tag.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)

                        Text(draft.duration.awarenessDurationLabel)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Button {
                        store.removeSelectedDraft()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .background(.thinMaterial, in: Circle())
                }

                VStack(spacing: 10) {
                    DatePicker(
                        "Starts",
                        selection: Binding(
                            get: { store.startDate(for: draft.id) },
                            set: { store.updateStartDate($0, for: draft.id) }
                        ),
                        in: store.startDateRange(for: draft.id),
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "Ends",
                        selection: Binding(
                            get: { store.endDate(for: draft.id) },
                            set: { store.updateEndDate($0, for: draft.id) }
                        ),
                        in: store.endDateRange(for: draft.id),
                        displayedComponents: .hourAndMinute
                    )
                }
                .font(.subheadline.weight(.semibold))
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

#Preview {
    ClaimTimeScene(
        segment: AwarenessTimelineSegment(
            id: AwarenessTimelineSegment.unclaimedID,
            title: AwarenessTimelineSegment.unclaimedTitle,
            duration: 90 * 60,
            color: .gray,
            startDate: Date().addingTimeInterval(-90 * 60),
            endDate: Date()
        )
    )
    .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
