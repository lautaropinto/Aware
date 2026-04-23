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
        let summary = store.summary()
        let model = accessoryModel(summary: summary)

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
            TimerAccessoryDetailScene(timer: activeTimer)
        }
    }

    private func accessoryModel(summary: AwarenessTimeSummary) -> TimerAccessoryModel {
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

        return TimerAccessoryModel(
            title: "Unclaimed time",
            color: .gray,
            timer: nil,
            timeDisplay: .ticking(
                baseDuration: summary.unclaimedTime,
                referenceDate: .now,
                rebaseNotification: .timerAccessorySummaryDidUpdate
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

    let timer: Timekeeper?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(timer?.mainTag?.name ?? timer?.name ?? "Unclaimed time")
                    .font(.largeTitle.bold())

                Text("Timer detail")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimerAccessoryView()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
