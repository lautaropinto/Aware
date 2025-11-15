//
//  RateAppPromptModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/16/25.
//

import SwiftUI
import SwiftData
import StoreKit
import AwareData

struct RateAppPromptModifier: ViewModifier {
    @Environment(Storage.self) private var storage
    
    @State private var completedTimers: [Timekeeper] = []
    @State private var shouldShowPrompt = false

    private enum UserDefaultsKeys {
        static let hasShownRatePrompt = "hasShownRatePrompt"
        static let lastPromptDate = "lastPromptDate"
    }

    func body(content: Content) -> some View {
        content
            .alert("Enjoying Aware?", isPresented: $shouldShowPrompt) {
                Button("Sure") {
                    requestAppStoreReview()
                    markPromptAsShown()
                }
                Button("Maybe later", role: .cancel) {
                    markPromptAsShown()
                }
            } message: {
                Text("A short rating helps others find a calmer way to notice their time.")
            }
            .onReceive(NotificationCenter.default.publisher(for: .timerDidStop)) { _ in
                checkAndShowPromptIfNeeded()
            }
            .onAppear {
                let predicate = #Predicate<Timekeeper> { $0.endTime != nil }
                self.completedTimers = storage.getTimers(predicate)
            }
    }

    private func checkAndShowPromptIfNeeded() {
        // Early exit if prompt has already been shown
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasShownRatePrompt) else {
            return
        }

        // Check criteria: 7+ completed timers
        guard completedTimers.count >= 7 else {
            return
        }

        // Check criteria: 3+ days of usage
        guard hasUsedAppForAtLeastThreeDays() else {
            return
        }

        // All criteria met - show the prompt after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            shouldShowPrompt = true
        }
    }

    private func hasUsedAppForAtLeastThreeDays() -> Bool {
        let allTimerDates = completedTimers.compactMap { $0.creationDate }
        guard let earliestDate = allTimerDates.min(),
              let latestDate = allTimerDates.max() else {
            return false
        }

        let daysBetween = Calendar.current.dateComponents([.day], from: earliestDate, to: latestDate).day ?? 0
        return daysBetween >= 3
    }

    private func requestAppStoreReview() {
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    private func markPromptAsShown() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasShownRatePrompt)
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastPromptDate)
    }
}

extension View {
    func rateAppPrompt() -> some View {
        modifier(RateAppPromptModifier())
    }
}

extension Notification.Name {
    static let timerDidStop = Notification.Name("timerDidStop")
}
