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

        let referenceDate = store.latestEndedActivityDate() ?? .now

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

private struct TimerAccessoryDetailScene: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Storage.self) private var storage
    @Environment(AwarenessSession.self) private var awarenessSession

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

        return latestEndedToday ?? now
    }

    private var switchTags: [Tag] {
        guard let currentTagID = currentTimer?.mainTag?.id else {
            return storage.tags
        }

        return storage.tags.filter { $0.id != currentTagID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    currentActivitySection
                    switchToSection
                    addActivitySection
                    moreActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .applyBackgroundGradient(.toBottom)
            .toolbar {
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
            Button {
                // Intentionally left empty for now.
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
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var moreActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Button {
                    // Intentionally no-op for now.
                } label: {
                    actionRow(icon: "timer", title: "Adjust time")
                }
                .buttonStyle(.plain)

                Button {
                    stopCurrentActivity()
                } label: {
                    actionRow(icon: "stop.fill", title: "Stop activity")
                }
                .buttonStyle(.plain)
                .disabled(currentTimer == nil)
                .opacity(currentTimer == nil ? 0.4 : 1)
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
        if let timer, let timerInterval {
            Text(timerInterval: timerInterval, countsDown: false)
        } else if let timer {
            Text(timer.currentElapsedTime.formattedElapsedTime)
        } else {
            Text(timerInterval: unclaimedInterval, countsDown: false)
        }
    }
}

#Preview {
    TimerAccessoryView()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
