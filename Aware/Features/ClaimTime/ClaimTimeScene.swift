//
//  ClaimTimeScene.swift
//  Aware
//
//  Created by Codex on 4/30/26.
//

import SwiftUI
import UIKit
import AwareData

struct ClaimTimeScene: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Storage.self) private var storage
    @State private var store: ClaimTimeStore
    @FocusState private var focusedActivityID: UUID?

    init(segment: AwarenessTimelineSegment) {
        _store = State(initialValue: ClaimTimeStore(segment: segment))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        clearFocus()
                    }

                GeometryReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ClaimTimeSegmentedTimeline(store: store)
                            ClaimTimePromptForm(
                                store: store,
                                focusedActivityID: $focusedActivityID
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
                        .background {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    clearFocus()
                                }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .applyBackgroundGradient(.toBottom)
            .safeAreaInset(edge: .bottom) {
                ClaimTimeFloatingAccessory(store: store)
            }
            .sheet(item: timePickerBinding) { _ in
                ClaimTimeTimePickerPanel(store: store)
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(28)
                    .presentationBackgroundInteraction(.enabled)
            }
            .navigationTitle("What were you doing?")
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

    private var timePickerBinding: Binding<ClaimTimeTimePickerContext?> {
        Binding(
            get: {
                guard let activeField = store.activeField, activeField.isTimeField else {
                    return nil
                }

                return ClaimTimeTimePickerContext(field: activeField)
            },
            set: { context in
                if context == nil, store.activeField?.isTimeField == true {
                    store.activeField = nil
                }
            }
        )
    }

    private func clearFocus() {
        focusedActivityID = nil
        store.activeField = nil
    }
}

private struct ClaimTimeTimePickerContext: Identifiable {
    let field: ClaimTimeFormField

    var id: String {
        switch field {
        case .activity(let draftID):
            return "activity-\(draftID)"
        case .start(let draftID), .end(let draftID):
            return "time-\(draftID)"
        }
    }
}

private struct ClaimTimePromptForm: View {
    let store: ClaimTimeStore
    let focusedActivityID: FocusState<UUID?>.Binding

    var body: some View {
        WrappingLayout(spacing: 6) {
            ForEach(tokens) { token in
                ClaimTimeParagraphTokenView(
                    store: store,
                    token: token,
                    focusedActivityID: focusedActivityID,
                    canAddDraft: store.canAddDraft
                ) {
                    addDraft()
                }
            }
        }
        .animation(.smooth(duration: 0.22), value: store.formDrafts.map(\.id))
        .onChange(of: focusedActivityID.wrappedValue) { _, newValue in
            if let newValue {
                store.activeField = .activity(newValue)
            }
        }
        .onChange(of: store.activeField) { _, newValue in
            if case .activity(let draftID) = newValue {
                focusedActivityID.wrappedValue = draftID
            } else {
                focusedActivityID.wrappedValue = nil
            }
        }
    }

    private var tokens: [ClaimTimeParagraphToken] {
        var result: [ClaimTimeParagraphToken] = []
        let drafts = store.formDrafts

        for (index, draft) in drafts.enumerated() {
            if index == 0 {
                result.append(.phrase("I was", id: "intro"))
            }

            result.append(.activity(draft))
            result.append(.phrase("from", id: "from-\(draft.id)"))
            result.append(.time(.start(draft.id)))
            result.append(.phrase("to", id: "to-\(draft.id)"))
            result.append(.time(.end(draft.id)))
            result.append(.punctuation(index == drafts.count - 1 ? "..." : ".", id: "punctuation-\(draft.id)"))
        }

        if !drafts.isEmpty {
            result.append(.whatElse)
        }

        return result
    }

    private func addDraft() {
        if let draftID = store.addDraft() {
            focusedActivityID.wrappedValue = draftID
        }
    }
}

private struct ClaimTimeParagraphToken: Identifiable {
    enum Kind {
        case phrase(String)
        case activity(ClaimTimeDraft)
        case time(ClaimTimeFormField)
        case punctuation(String)
        case whatElse
    }

    let id: String
    let kind: Kind

    static func phrase(_ value: String, id: String) -> ClaimTimeParagraphToken {
        ClaimTimeParagraphToken(id: id, kind: .phrase(value))
    }

    static func activity(_ draft: ClaimTimeDraft) -> ClaimTimeParagraphToken {
        ClaimTimeParagraphToken(id: "activity-\(draft.id)", kind: .activity(draft))
    }

    static func time(_ field: ClaimTimeFormField) -> ClaimTimeParagraphToken {
        switch field {
        case .activity(let draftID):
            return ClaimTimeParagraphToken(id: "activity-time-\(draftID)", kind: .time(field))
        case .start(let draftID):
            return ClaimTimeParagraphToken(id: "start-\(draftID)", kind: .time(field))
        case .end(let draftID):
            return ClaimTimeParagraphToken(id: "end-\(draftID)", kind: .time(field))
        }
    }

    static func punctuation(_ value: String, id: String) -> ClaimTimeParagraphToken {
        ClaimTimeParagraphToken(id: id, kind: .punctuation(value))
    }

    static var whatElse: ClaimTimeParagraphToken {
        ClaimTimeParagraphToken(id: "what-else", kind: .whatElse)
    }
}

private struct ClaimTimeParagraphTokenView: View {
    let store: ClaimTimeStore
    let token: ClaimTimeParagraphToken
    let focusedActivityID: FocusState<UUID?>.Binding
    let canAddDraft: Bool
    let addDraft: () -> Void

    var body: some View {
        Group {
            switch token.kind {
            case .phrase(let value):
                Text(value)
                    .claimTimePhraseText()

            case .activity(let draft):
                activityField(for: draft)

            case .time(let field):
                timePill(title: title(for: field), field: field)

            case .punctuation(let value):
                Text(value)
                    .claimTimePhraseText()
                    .foregroundStyle(.secondary)

            case .whatElse:
                whatElseButton
            }
        }
        .opacity(tokenOpacity)
        .animation(.smooth(duration: 0.18), value: store.activeField)
    }

    private func activityField(for draft: ClaimTimeDraft) -> some View {
        let activityWidth = activityTextFieldWidth(for: draft)

        return HStack(spacing: 4) {
            TextField("doing something", text: Binding(
                get: { store.activityName(for: draft.id).lowercased() },
                set: { store.updateActivityName($0, for: draft.id) }
            ))
            .font(.title3.weight(.semibold))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .submitLabel(.next)
            .focused(focusedActivityID, equals: draft.id)
            .onSubmit {
                store.acceptTypedActivity(for: draft.id)
            }
            .lineLimit(1)
            .frame(width: activityWidth)

            if store.formDrafts.count > 1 {
                Button {
                    store.removeDraft(draft.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(
            (draft.hasActivity ? draft.color.opacity(0.14) : Color.primary.opacity(0.08)),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(draft.hasActivity ? draft.color.opacity(0.26) : Color.secondary.opacity(0.18), lineWidth: 1)
        }
    }

    private func activityTextFieldWidth(for draft: ClaimTimeDraft) -> CGFloat {
        let text = draft.hasActivity ? store.activityName(for: draft.id).lowercased() : "doing something"
        let removeButtonWidth: CGFloat = store.formDrafts.count > 1 ? 22 : 0
        let horizontalPadding: CGFloat = 24
        let maxTokenWidth = CGRect.screenBounds.width - 40
        let maxTextWidth = max(88, maxTokenWidth - horizontalPadding - removeButtonWidth)
        let measuredWidth = text.claimTimeActivityTextWidth + 2

        return min(max(88, measuredWidth), maxTextWidth)
    }

    private func title(for field: ClaimTimeFormField) -> String {
        switch field {
        case .activity(let draftID), .start(let draftID):
            return store.startDate(for: draftID).formattedTime
        case .end(let draftID):
            return store.endDate(for: draftID).formattedTime
        }
    }

    private func timePill(title: String, field: ClaimTimeFormField) -> some View {
        Button {
            store.activeField = field
        } label: {
            Text(title)
                .font(.title3.monospacedDigit().weight(.semibold))
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(
                    isActive(field) ? Color.accent.opacity(0.18) : Color.primary.opacity(0.08),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(isActive(field) ? Color.accent.opacity(0.42) : Color.secondary.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func isActive(_ field: ClaimTimeFormField) -> Bool {
        store.activeField == field
    }

    private var tokenOpacity: Double {
        guard let activeField = store.activeField else { return 1 }

        switch token.kind {
        case .activity(let draft):
            return activeField == .activity(draft.id) ? 1 : 0.28
        case .time(let field):
            return activeField == field ? 1 : 0.28
        case .phrase, .punctuation, .whatElse:
            return 0.28
        }
    }

    private var whatElseButton: some View {
        Button {
            addDraft()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))

                Text("What else?")
            }
            .claimTimePhraseText()
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(!canAddDraft)
    }
}

private struct ClaimTimeFloatingAccessory: View {
    let store: ClaimTimeStore

    var body: some View {
        if case .activity(let draftID) = store.activeField, !store.activitySuggestions(for: draftID).isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.activitySuggestions(for: draftID), id: \.id) { tag in
                        Button {
                            store.selectActivity(tag, for: draftID)
                        } label: {
                            ClaimTimeSuggestionPill(
                                iconName: iconName(for: tag.image),
                                title: tag.name,
                                color: tag.swiftUIColor
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
            .glassEffect()
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct ClaimTimeTimePickerPanel: View {
    let store: ClaimTimeStore

    var body: some View {
        if let field = store.activeField, field.isTimeField {
            VStack(spacing: 8) {
                HStack {
                    ClaimTimePickerNavigationButton(systemName: "chevron.left") {
                        store.retreat(from: field)
                    }

                    Spacer()

                    ClaimTimePickerNavigationButton(systemName: isFinalStep(field) ? "chevron.down" : "chevron.right") {
                        store.advance(from: field)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)

                VStack(spacing: 0) {
                    Text(fieldTitle(for: field))
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text(currentDate(for: field).formattedTime)
                        .font(.system(size: 66, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: currentDate(for: field).timeIntervalSinceReferenceDate))
                        .animation(.smooth(duration: 0.18), value: currentDate(for: field))
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .center)
                
                Spacer()
                
                ClaimTimeWheelPicker(store: store, field: field)
                    .padding(.horizontal, 20)
                    .padding(.bottom)
            }
        }
    }

    private func fieldTitle(for field: ClaimTimeFormField) -> String {
        switch field {
        case .activity, .start:
            return "Started at"
        case .end:
            return "Ended at"
        }
    }

    private func currentDate(for field: ClaimTimeFormField) -> Date {
        switch field {
        case .activity:
            return store.intervalStart
        case .start(let draftID):
            return store.startDate(for: draftID)
        case .end(let draftID):
            return store.endDate(for: draftID)
        }
    }

    private func isFinalStep(_ field: ClaimTimeFormField) -> Bool {
        if case .end = field {
            return true
        }

        return false
    }
}

private struct ClaimTimePickerNavigationButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 38, height: 38)
        }
        .claimTimeGlassButton()
    }
}

private extension View {
    func claimTimePhraseText() -> some View {
        self
            .font(.title3.weight(.semibold))
            .frame(height: 40, alignment: .center)
    }

    @ViewBuilder
    func claimTimeGlassButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

private extension String {
    var claimTimeActivityTextWidth: CGFloat {
        let pointSize = UIFont.preferredFont(forTextStyle: .title3).pointSize
        let font = UIFont.systemFont(ofSize: pointSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        return ceil((self as NSString).size(withAttributes: attributes).width)
    }
}

private extension CGRect {
    static var screenBounds: CGRect {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .bounds ?? CGRect(x: 0, y: 0, width: 390, height: 844)
    }
}

private struct ClaimTimeSuggestionPill: View {
    let iconName: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

private struct ClaimTimeWheelPicker: View {
    let store: ClaimTimeStore
    let field: ClaimTimeFormField

    @State private var feedbackGenerator = UISelectionFeedbackGenerator()
    @State private var selectedIndex = 0
    @State private var dragStartIndex: Int?
    @State private var dragTranslation: CGFloat = 0

    private let tickSpacing: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2

            ZStack {
                ForEach(ticks.indices, id: \.self) { index in
                    let x = centerX + CGFloat(index - selectedIndex) * tickSpacing + dragTranslation

                    ClaimTimeRulerTick(
                        distanceFromCenter: abs(x - centerX) / tickSpacing,
                        isMajor: index.isMultiple(of: 3)
                    )
                    .position(x: x, y: proxy.size.height - 16)
                }

                Capsule()
                    .fill(Color.red.gradient)
                    .frame(width: 6, height: 38)
                    .position(x: centerX, y: proxy.size.height - 19)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .frame(height: 58)
        .clipped()
        .onAppear {
            selectedIndex = nearestTickIndex(to: currentDate)
            feedbackGenerator.prepare()
        }
        .onChange(of: field) { _, _ in
            selectedIndex = nearestTickIndex(to: currentDate)
            dragStartIndex = nil
            dragTranslation = 0
        }
        .onChange(of: currentDate) { _, newValue in
            guard dragStartIndex == nil else { return }
            selectedIndex = nearestTickIndex(to: newValue)
        }
    }

    private var ticks: [Date] {
        store.timeTicks(for: field)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartIndex == nil {
                    dragStartIndex = selectedIndex
                }

                let baseIndex = dragStartIndex ?? selectedIndex
                let proposedIndex = baseIndex - Int((value.translation.width / tickSpacing).rounded())
                let clampedIndex = min(max(proposedIndex, ticks.startIndex), max(ticks.endIndex - 1, ticks.startIndex))
                dragTranslation = value.translation.width + CGFloat(clampedIndex - baseIndex) * tickSpacing

                guard clampedIndex != selectedIndex else { return }
                selectedIndex = clampedIndex
                updateSelection(to: clampedIndex)
            }
            .onEnded { _ in
                dragStartIndex = nil
                dragTranslation = 0
                selectedIndex = nearestTickIndex(to: currentDate)
            }
    }

    private var currentDate: Date {
        switch field {
        case .activity:
            store.intervalStart
        case .start(let draftID):
            store.startDate(for: draftID)
        case .end(let draftID):
            store.endDate(for: draftID)
        }
    }

    private func nearestTickIndex(to date: Date) -> Int {
        guard !ticks.isEmpty else { return 0 }

        return ticks.indices.min { lhs, rhs in
            abs(ticks[lhs].timeIntervalSince(date)) < abs(ticks[rhs].timeIntervalSince(date))
        } ?? 0
    }

    private func updateSelection(to index: Int) {
        guard ticks.indices.contains(index) else { return }

        switch field {
        case .activity:
            break
        case .start(let draftID):
            store.updateStartDate(ticks[index], for: draftID)
        case .end(let draftID):
            store.updateEndDate(ticks[index], for: draftID)
        }

        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
    }
}

private struct ClaimTimeRulerTick: View {
    let distanceFromCenter: CGFloat
    let isMajor: Bool

    var body: some View {
        Capsule()
            .fill(Color.secondary.opacity(opacity))
            .frame(width: width, height: height)
            .frame(height: 38, alignment: .bottom)
    }

    private var height: CGFloat {
        let clampedDistance = min(distanceFromCenter, 7)
        let proximity = max(0, 1 - clampedDistance / 7)
        let easedProximity = proximity * proximity

        return 4 + easedProximity * 27
    }

    private var width: CGFloat {
        distanceFromCenter > 6 ? 4 : 3
    }

    private var opacity: Double {
        let clampedDistance = min(distanceFromCenter, 7)
        return 0.22 + Double(max(0, 1 - clampedDistance / 7)) * 0.42
    }
}

private struct ClaimTimeSegmentedTimeline: View {
    let store: ClaimTimeStore

    private let segmentSpacing: CGFloat = 2
    private let minimumSegmentWidth: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let segments = store.timelineSegments
                let totalSpacing = CGFloat(max(segments.count - 1, 0)) * segmentSpacing
                let availableWidth = max(0, width - totalSpacing)
                let segmentWidths = visibleSegmentWidths(totalWidth: availableWidth, segments: segments)
                let offsets = segmentWidths.reduce(into: [CGFloat]()) { partialResult, segmentWidth in
                    partialResult.append((partialResult.last ?? 0) + segmentWidth + segmentSpacing)
                }

                ZStack(alignment: .leading) {
                    let activeDraftID = store.activeField?.draftID
                    let hasFocusedSegment = activeDraftID.map { draftID in
                        segments.contains { $0.draftID == draftID }
                    } ?? false

                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        let offset = index == 0 ? 0 : offsets[index - 1]

                        ClaimTimeTimelineBlock(
                            segment: segment,
                            isDimmed: hasFocusedSegment && segment.draftID != activeDraftID
                        )
                            .frame(width: segmentWidths[index], height: proxy.size.height)
                            .offset(x: offset)
                            .accessibilityLabel(segment.title)
                            .accessibilityValue(segment.duration.awarenessDurationLabel)
                    }
                }
            }
            .frame(height: 74)

            HStack {
                Text(store.intervalStart.formattedTime)
                Spacer()
                Text(store.intervalEnd.formattedTime)
            }
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .animation(.smooth(duration: 0.28), value: timelineAnimationKey)
        .animation(.smooth(duration: 0.18), value: store.activeField)
    }

    private var timelineAnimationKey: [String] {
        store.timelineSegments.map { segment in
            [
                segment.id,
                String(segment.startDate.timeIntervalSince1970),
                String(segment.endDate.timeIntervalSince1970)
            ].joined(separator: "-")
        }
    }

    private func visibleSegmentWidths(totalWidth: CGFloat, segments: [ClaimTimeTimelineSegment]) -> [CGFloat] {
        let rawWidths: [CGFloat] = segments.map { segment in
            guard store.duration > 0 else { return 0 }
            return max(0, totalWidth * CGFloat(segment.duration / store.duration))
        }
        let nonzeroIndexes = rawWidths.indices.filter { rawWidths[$0] > 0 }
        let minimumTotalWidth = CGFloat(nonzeroIndexes.count) * minimumSegmentWidth

        guard minimumTotalWidth <= totalWidth else {
            return rawWidths
        }

        let rawTotalWidth = rawWidths.reduce(0, +)
        let extraWidth = min(totalWidth, rawTotalWidth) - minimumTotalWidth

        guard extraWidth > 0, rawTotalWidth > 0 else {
            return rawWidths.enumerated().map { index, width in
                nonzeroIndexes.contains(index) ? minimumSegmentWidth : width
            }
        }

        return rawWidths.enumerated().map { index, width in
            guard nonzeroIndexes.contains(index) else { return width }
            return minimumSegmentWidth + (width / rawTotalWidth) * extraWidth
        }
    }
}

private struct ClaimTimeTimelineBlock: View {
    let segment: ClaimTimeTimelineSegment
    let isDimmed: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.08))
            .overlay {
                if segment.isUnclaimed {
                    ClaimTimeStripeOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(segment.color.gradient)
                }
            }
            .overlay(alignment: .bottomLeading) {
                GeometryReader { proxy in
                    if segment.isUnclaimed {
                        if proxy.size.width < 54 {
                            Image(systemName: iconName(for: segment.iconName))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(6)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(segment.title)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)

                                Text(segment.duration.awarenessDurationLabel)
                                    .font(.caption2.monospacedDigit().weight(.semibold))
                                    .lineLimit(1)
                                    .contentTransition(.numericText(value: segment.duration))
                            }
                            .foregroundStyle(.secondary)
                            .padding(7)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: iconName(for: segment.iconName))
                                .font(.system(size: proxy.size.width < 54 ? 15 : 18, weight: .bold))

                            if proxy.size.width >= 54 {
                                Text(segment.duration.awarenessDurationLabel)
                                    .font(.caption2.monospacedDigit().weight(.semibold))
                                    .lineLimit(1)
                                    .contentTransition(.numericText(value: segment.duration))
                            }
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(6)
                    }
                }
            }
            .opacity(isDimmed ? 0.24 : 1)
            .saturation(isDimmed ? 0.55 : 1)
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

private func iconName(for storedIconName: String) -> String {
    storedIconName == "placeholder" || storedIconName.isEmpty ? "circle.dashed" : storedIconName
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
