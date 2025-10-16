//
//  HomeScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI
import OSLog

private var logger = Logger(subsystem: "Aware", category: "HomeScene")

struct HomeScene: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appConfig) private var config
    @Environment(ActivityStore.self) private var activityStore
    @Environment(\.scenePhase) var scenePhase
    
    @Query private var timers: [Timekeeper]
    @Query private var tags: [Tag]
    
    @State private var currentTimer: Timekeeper?
    @State private var showingNewTimerSheet = false
    @State private var selectedTag: Tag?
    @State private var newTimerName = ""
    
    @Namespace private var settingsTransition
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Unified Timer Section
                    StopWatch(timer: currentTimer, onStateChange: refreshCurrentTimer)
                        .rateAppPrompt()
                        .padding(.horizontal)
                    
                    // Quick Start Section
                    QuickStartSection(
                        isDisabled: currentTimer != nil,
                        onTagSelected: { tag in
                            createAndStartTimer(with: tag)
                        }
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentTimer != nil)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: currentTimer != nil)
                .padding()
            }
            .applyBackgroundGradient()
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton(transition: settingsTransition)
                }
                .matchedTransitionSource(id: "settings", in: settingsTransition)
            }
        }
        .onAppear {
            logger.debug("onAppear()")
            findCurrentTimer()
        }
        .onChange(of: currentTimer) { _, newValue in
            guard let timerColor = newValue?.mainTag?.swiftUIColor else {
                withAnimation { config.backgroundColor = .teal }
                return
            }
            withAnimation { config.backgroundColor = timerColor }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                findCurrentTimer()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaultTags() {
        if tags.isEmpty {
            for defaultTag in Tag.defaultTags {
                modelContext.insert(defaultTag)
            }
            try? modelContext.save()
        }
    }
    
    private func findCurrentTimer() {
        currentTimer = timers.first { timer in
            timer.isRunning || (timer.totalElapsedSeconds > 0 && timer.endTime == nil)
        }
        
        if let currentTimer {
            activityStore.timer = currentTimer
            logger.debug("Starting activity with timer: \(currentTimer.formattedElapsedTime)")
            activityStore.startLiveActivity(with: currentTimer)
        }
    }
    
    private func refreshCurrentTimer() {
        currentTimer = timers.first { timer in
            timer.isRunning || (timer.totalElapsedSeconds > 0 && timer.endTime == nil)
        }
    }
    
    private func createAndStartTimer(with tag: Tag) {
        let timer = Timekeeper(name: "\(tag.name) Session", tags: [tag])
        modelContext.insert(timer)
        timer.start()
        currentTimer = timer
        activityStore.timer = timer
        activityStore.startLiveActivity(with: timer)
        try? modelContext.save()
    }
    
    private func createTimer(name: String, tag: Tag?) {
        guard let tag else { return }
        
        let timer = Timekeeper(name: name, tags: [tag])
        modelContext.insert(timer)
        try? modelContext.save()
        showingNewTimerSheet = false
        newTimerName = ""
        selectedTag = nil
    }
}

#Preview {
    HomeScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
