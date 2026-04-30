//
//  TimerAccessoryView.swift
//  Aware
//
//  Created by Codex on 4/22/26.
//

import SwiftUI
import UIKit
import AwareData

struct TimerAccessoryView: View {
    @Environment(Storage.self) private var storage
    @Environment(AwarenessSession.self) private var awarenessSession

    @State private var store = TimerAccessoryStore()
    @State private var isDetailPresented = false

    private var activeTimer: Timekeeper? {
        awarenessSession.activeTimer
    }

    var body: some View {
        let model = accessoryModel()

        TimerAccessoryContent(
            model: model,
            onOpenDetail: { isDetailPresented = true }
        )
        .onAppear {
            store.configure(storage: storage, healthKitManager: HealthKitManager.shared)
            store.refreshData()
        }
        .onChange(of: storage.changeToken) {
            store.refreshData()
        }
        .fullScreenCover(isPresented: $isDetailPresented) {
            TimerAccessoryDetailScene()
        }
    }

    private func accessoryModel() -> TimerAccessoryModel {
        if let activeTimer {
            let timeDisplay: TimerAccessoryTimeDisplay

            if activeTimer.isRunning, let startTime = activeTimer.startTime {
                timeDisplay = .ticking(
                    baseDuration: activeTimer.totalElapsedSeconds,
                    referenceDate: startTime,
                    rebaseNotification: nil
                )
            } else {
                timeDisplay = .staticDuration(activeTimer.currentElapsedTime)
            }

            return TimerAccessoryModel(
                title: activeTimer.mainTag?.name ?? activeTimer.name,
                color: activeTimer.swiftUIColor,
                timer: activeTimer,
                timeDisplay: timeDisplay
            )
        }

        let referenceDate = store.latestEndedActivityDate() ?? Calendar.current.startOfDay(for: .now)

        return TimerAccessoryModel(
            title: "Unclaimed time",
            color: .gray,
            timer: nil,
            timeDisplay: .ticking(
                baseDuration: 0,
                referenceDate: referenceDate,
                rebaseNotification: nil
            )
        )
    }
}

private struct TimerAccessoryModel {
    let title: String
    let color: Color
    let timer: Timekeeper?
    let timeDisplay: TimerAccessoryTimeDisplay
}

private enum TimerAccessoryTimeDisplay {
    case ticking(baseDuration: TimeInterval, referenceDate: Date, rebaseNotification: Notification.Name?)
    case staticDuration(TimeInterval)
}

private struct TimerAccessoryContent: View {
    let model: TimerAccessoryModel
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(model.color.gradient)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: model.timer == nil ? "questionmark" : "timer")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .imageScale(.small)
                    }

                HStack(spacing: 7) {
                    Text(model.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Circle()
                        .fill(.secondary)
                        .frame(width: 4, height: 4)
                        .accessibilityHidden(true)

                    accessoryTime
                }

                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .frame(height: 56)
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var accessoryTime: some View {
        switch model.timeDisplay {
        case let .ticking(baseDuration, referenceDate, rebaseNotification):
            TickingElapsedText(
                baseDuration: baseDuration,
                referenceDate: referenceDate,
                rebaseNotification: rebaseNotification
            )
                .frame(height: 16, alignment: .leading)

        case let .staticDuration(elapsedTime):
            Text(elapsedTime.formattedElapsedTime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

private struct TickingElapsedText: UIViewRepresentable {
    let baseDuration: TimeInterval
    let referenceDate: Date
    let rebaseNotification: Notification.Name?

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular)
        label.textColor = .secondaryLabel
        label.font = .monospacedSystemFont(ofSize: 14.0, weight: .bold)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        context.coordinator.attach(label)
        context.coordinator.configure(
            baseDuration: baseDuration,
            referenceDate: referenceDate,
            rebaseNotification: rebaseNotification
        )
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        context.coordinator.attach(label)
        context.coordinator.configure(
            baseDuration: baseDuration,
            referenceDate: referenceDate,
            rebaseNotification: rebaseNotification
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private weak var label: UILabel?
        private var timer: Timer?
        private var baseDuration: TimeInterval = 0
        private var referenceDate = Date()
        private var notificationObserver: NSObjectProtocol?
        private var rebaseNotification: Notification.Name?

        deinit {
            timer?.invalidate()
            if let notificationObserver {
                NotificationCenter.default.removeObserver(notificationObserver)
            }
        }

        func attach(_ label: UILabel) {
            self.label = label

            guard timer == nil else { return }

            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                self?.updateLabel()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }

        func configure(
            baseDuration: TimeInterval,
            referenceDate: Date,
            rebaseNotification: Notification.Name?
        ) {
            self.baseDuration = baseDuration
            self.referenceDate = referenceDate
            configureRebaseNotification(rebaseNotification)
            updateLabel()
        }

        private func configureRebaseNotification(_ notificationName: Notification.Name?) {
            guard rebaseNotification != notificationName else { return }

            if let notificationObserver {
                NotificationCenter.default.removeObserver(notificationObserver)
                self.notificationObserver = nil
            }

            rebaseNotification = notificationName

            guard let notificationName else { return }

            notificationObserver = NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.rebase(from: notification)
            }
        }

        private func rebase(from notification: Notification) {
            guard
                let unclaimedTime = notification.userInfo?[TimerAccessorySummaryNotificationKey.unclaimedTime] as? TimeInterval,
                let date = notification.userInfo?[TimerAccessorySummaryNotificationKey.date] as? Date
            else { return }

            baseDuration = unclaimedTime
            referenceDate = date
            updateLabel()
        }

        private func updateLabel() {
            let elapsedTime = max(0, baseDuration + Date().timeIntervalSince(referenceDate))
            label?.text = elapsedTime.formattedElapsedTime
        }
    }
}

private enum TimerAccessoryDetailMode {
    case timer
    case endEarlier
}

private struct TimerAccessoryDetailScene: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Storage.self) private var storage
    @Environment(AwarenessSession.self) private var awarenessSession
    @FocusState private var isNewActivityNameFocused: Bool

    @State private var isAddingNewActivity = false
    @State private var detailMode: TimerAccessoryDetailMode = .timer
    @State private var endEarlierEndTime = Date()
    @State private var endEarlierMaxEndTime = Date()
    @State private var newActivityName = ""
    @State private var newActivityIcon = "heart.fill"
    @State private var newActivityColor: Color = .accent
    @Namespace private var addActivityNamespace
    @Namespace private var detailTransitionNamespace

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var currentTimer: Timekeeper? {
        awarenessSession.activeTimer
    }

    private var unclaimedReferenceDate: Date {
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        let latestEndedToday = storage.timers
            .compactMap(\.endTime)
            .filter { $0 >= dayStart && $0 <= now }
            .max()

        return latestEndedToday ?? dayStart
    }

    private var switchTags: [Tag] {
        guard let currentTagID = currentTimer?.mainTag?.id else {
            return storage.tags
        }

        return storage.tags.filter { $0.id != currentTagID }
    }

    private var duplicateExistingTag: Tag? {
        let normalizedName = normalizeActivityName(newActivityName)
        guard !normalizedName.isEmpty else { return nil }

        return storage.tags.first { normalizeActivityName($0.name) == normalizedName }
    }

    private var isCreateActivityEnabled: Bool {
        !newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && duplicateExistingTag == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                detailContent
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .contentShape(Rectangle())
            .gesture(
                TapGesture().onEnded {
                    collapseAddActivityFormIfNeeded()
                },
                including: .gesture
            )
            .applyBackgroundGradient(.toBottom)
            .toolbar {
                if detailMode == .endEarlier {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            cancelEndEarlierEdit()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            confirmEndEarlierEdit()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if detailMode == .endEarlier, let currentTimer {
            EndEarlierTimerEditor(
                timer: currentTimer,
                endTime: $endEarlierEndTime,
                maxEndTime: endEarlierMaxEndTime,
                namespace: detailTransitionNamespace
            )
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                )
            )
        } else {
            VStack(alignment: .leading, spacing: 28) {
                currentActivitySection
                switchToSection
                addActivitySection
                moreActionsSection
            }
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .leading)),
                    removal: .opacity.combined(with: .move(edge: .trailing))
                )
            )
        }
    }

    private var currentActivitySection: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(currentTimer?.swiftUIColor ?? .gray)
                    .frame(width: 10, height: 10)

                Text(currentTimer?.mainTag?.name ?? currentTimer?.name ?? "Unclaimed time")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
            }
            .matchedGeometryEffect(id: "currentActivitySummary", in: detailTransitionNamespace)

            DetailElapsedTimerText(
                timer: currentTimer,
                unclaimedReferenceDate: unclaimedReferenceDate
            )
                .font(.system(size: 58, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.numericText(value: currentTimer?.currentElapsedTime ?? 0))
        }
    }

    private var switchToSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(switchTags, id: \.id) { tag in
                    Button {
                        switchToActivity(tag)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tag.image.isEmpty ? "circle.fill" : tag.image)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(tag.swiftUIColor)

                            Text(tag.name)
                                .font(.headline)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var addActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isAddingNewActivity {
                addActivityInlineForm
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)),
                            removal: .opacity
                        )
                    )
            } else {
                addActivityButton
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.97))
                        )
                    )
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.28), value: isAddingNewActivity)
    }

    private var addActivityButton: some View {
        Button {
            withAnimation {
                isAddingNewActivity = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isNewActivityNameFocused = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.72))

                Text("Add new activity")
                    .font(.headline)
                    .foregroundStyle(.secondary.opacity(0.82))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .matchedGeometryEffect(id: "addActivityContainer", in: addActivityNamespace)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive())
    }

    private var addActivityInlineForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ColorPicker("", selection: $newActivityColor)
                    .labelsHidden()
                    .frame(width: 20, height: 20)

                TagIconPicker(selection: $newActivityIcon)
                    .tint(newActivityColor)

                TextField("Give this time a name", text: $newActivityName)
                    .textInputAutocapitalization(.words)
                    .focused($isNewActivityNameFocused)
                    .submitLabel(.go)
                    .onSubmit {
                        createActivityAndStartTimer()
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .matchedGeometryEffect(id: "addActivityContainer", in: addActivityNamespace)
            .glassEffect(.regular.interactive())
            HStack(spacing: 8) {
                if let duplicateExistingTag {
                    Text("Activity \"\(duplicateExistingTag.name)\" already exists.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
                
                Spacer(minLength: 0)

                Button {
                    cancelAddingActivity()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .background(.ultraThinMaterial, in: Circle())

                Button {
                    createActivityAndStartTimer()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(newActivityColor.gradient, in: Circle())
                .disabled(!isCreateActivityEnabled)
                .opacity(isCreateActivityEnabled ? 1 : 0.4)
            }
        }
        
    }

    private var moreActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                if currentTimer?.isRunning == true {
                    Button {
                        beginEndEarlierEdit()
                    } label: {
                        actionRow(icon: "timer", title: "End earlier")
                    }
                    .buttonStyle(.plain)
                }

                if currentTimer != nil {
                    Button {
                        stopCurrentActivity()
                    } label: {
                        actionRow(icon: "stop.fill", title: "Stop activity")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func actionRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func switchToActivity(_ tag: Tag) {
        if awarenessSession.activeTimer != nil {
            awarenessSession.stopTimer()
        }
        awarenessSession.startTimer(with: tag)
        dismiss()
    }

    private func stopCurrentActivity() {
        awarenessSession.stopTimer()
        dismiss()
    }

    private func beginEndEarlierEdit() {
        guard let timer = currentTimer, timer.isRunning else { return }

        endEarlierMaxEndTime = Date()
        endEarlierEndTime = endEarlierMaxEndTime
        endEarlierEndTime = min(max(endEarlierEndTime, timer.currentSessionStartDate), endEarlierMaxEndTime)

        withAnimation(.spring(duration: 0.56, bounce: 0.24)) {
            detailMode = .endEarlier
            isAddingNewActivity = false
        }
    }

    private func cancelEndEarlierEdit() {
        withAnimation(.spring(duration: 0.48, bounce: 0.22)) {
            detailMode = .timer
        }
    }

    private func confirmEndEarlierEdit() {
        awarenessSession.stopTimer(at: endEarlierEndTime)
        dismiss()
    }

    private func cancelAddingActivity() {
        withAnimation {
            isAddingNewActivity = false
        }
        resetAddActivityForm()
    }

    private func collapseAddActivityFormIfNeeded() {
        guard isAddingNewActivity else { return }
        cancelAddingActivity()
    }

    private func createActivityAndStartTimer() {
        let trimmedName = newActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard duplicateExistingTag == nil else { return }

        let nextDisplayOrder = (storage.tags.map(\.displayOrder).max() ?? -1) + 1
        let newTag = Tag(
            name: trimmedName,
            color: newActivityColor.toHex(),
            image: newActivityIcon,
            displayOrder: nextDisplayOrder
        )

        storage.insert(newTag)
        storage.save()

        if awarenessSession.activeTimer != nil {
            awarenessSession.stopTimer()
        }
        awarenessSession.startTimer(with: newTag)

        resetAddActivityForm()
        dismiss()
    }

    private func resetAddActivityForm() {
        newActivityName = ""
        newActivityIcon = "heart.fill"
        newActivityColor = .accent
        isNewActivityNameFocused = false
    }

    private func normalizeActivityName(_ rawValue: String) -> String {
        let normalized = rawValue
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))

        return normalized
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

private struct DetailElapsedTimerText: View {
    let timer: Timekeeper?
    let unclaimedReferenceDate: Date

    private var timerInterval: ClosedRange<Date>? {
        guard let timer, timer.isRunning, let startTime = timer.startTime else {
            return nil
        }

        let adjustedStartTime = startTime.addingTimeInterval(-timer.totalElapsedSeconds)
        return adjustedStartTime...Date(timeIntervalSinceNow: 360000)
    }

    private var unclaimedInterval: ClosedRange<Date> {
        unclaimedReferenceDate...Date(timeIntervalSinceNow: 360000)
    }

    var body: some View {
        if timer != nil, let timerInterval {
            Text(timerInterval: timerInterval, countsDown: false)
        } else if let timer {
            Text(timer.currentElapsedTime.formattedElapsedTime)
        } else {
            Text(timerInterval: unclaimedInterval, countsDown: false)
        }
    }
}

private struct EndEarlierTimerEditor: View {
    let timer: Timekeeper
    @Binding var endTime: Date
    let maxEndTime: Date
    let namespace: Namespace.ID

    private var startTime: Date {
        timer.currentSessionStartDate
    }

    private var color: Color {
        timer.swiftUIColor
    }

    private var activityName: String {
        timer.mainTag?.name ?? timer.name
    }

    private var clampedEndTime: Date {
        min(max(endTime, startTime), maxEndTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            currentActivitySummary

            VStack(alignment: .leading, spacing: 12.0) {
                Text("When did you stop?")
                    .font(.title2.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                EndTimeDragControl(
                    startTime: startTime,
                    endTime: $endTime,
                    maxEndTime: maxEndTime,
                    color: color
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            endTime = clampedEndTime
        }
        .animation(.smooth(duration: 0.22), value: clampedEndTime)
    }

    private var currentActivitySummary: some View {
        HStack(spacing: 12) {
            Image(systemName: timer.mainTag?.image.isEmpty == false ? timer.mainTag?.image ?? "timer" : "timer")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(activityName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text("Started at \(startTime.formattedTime)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .matchedGeometryEffect(id: "currentActivitySummary", in: namespace)
    }
}

private struct EndTimeDragControl: View {
    let startTime: Date
    @Binding var endTime: Date
    let maxEndTime: Date
    let color: Color

    private var clampedEndTime: Date {
        min(max(endTime, startTime), maxEndTime)
    }

    private var availableDuration: TimeInterval {
        max(1, maxEndTime.timeIntervalSince(startTime))
    }

    private var selectedDuration: TimeInterval {
        max(0, clampedEndTime.timeIntervalSince(startTime))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(clampedEndTime.formattedTime)
                .font(.system(size: 54, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let progress = selectedDuration / availableDuration
                let handleWidth: CGFloat = 38
                let handleOffset = max(0, min(width - handleWidth, (width - handleWidth) * progress))
                let fillWidth = max(handleWidth * 0.62, width * progress)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(color.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(color.opacity(0.2), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.95),
                                    color.opacity(0.72),
                                    color.opacity(0.36)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth)
                        .animation(.smooth(duration: 0.18), value: fillWidth)

                    HStack {
                        Spacer(minLength: 0)
                        Text(selectedDuration.compactFormattedTime)
                            .font(.headline.monospacedDigit().weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .contentTransition(.numericText(value: selectedDuration))
                    }
                    .padding(.horizontal, 22)
                    .allowsHitTesting(false)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(width: handleWidth)
                        .overlay {
                            Capsule()
                                .fill(.white.opacity(0.9))
                                .frame(width: 5, height: 44)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: color.opacity(0.25), radius: 18, y: 8)
                        .offset(x: handleOffset)
                        .animation(.spring(duration: 0.32, bounce: 0.22), value: handleOffset)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .frame(width: width, height: 74)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateEndTime(locationX: value.location.x, width: width)
                        }
                )
            }
            .frame(height: 74)

            HStack {
                Text(startTime.formattedTime)
                Spacer()
                Text(maxEndTime.formattedTime)
            }
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private func updateEndTime(locationX: CGFloat, width: CGFloat) {
        let progress = max(0, min(1, locationX / max(1, width)))
        let nextEndTime = startTime.addingTimeInterval(availableDuration * progress)

        endTime = min(max(nextEndTime, startTime), maxEndTime)
    }
}

#Preview {
    TimerAccessoryView()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
