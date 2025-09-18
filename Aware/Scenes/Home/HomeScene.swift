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

struct HomeScene: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appConfig) private var config
    
    @Query private var timers: [Timekeeper]
    @Query private var tags: [Tag]
    
    @State private var currentTimer: Timekeeper?
    @State private var showingNewTimerSheet = false
    @State private var selectedTag: Tag?
    @State private var newTimerName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Unified Timer Section
                    UnifiedTimerView(timer: currentTimer, onStateChange: refreshCurrentTimer)
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
            // Drive the gradient from the environment binding (same as $backgroundColor here)
            .applyBackgroundGradient()
            .navigationTitle("Timer")
        }
        // Publish the binding so all descendants share and can react to changes
        .onAppear {
            findCurrentTimer()
        }
        .onChange(of: currentTimer) { _, newValue in
            guard let timerColor = newValue?.mainTag?.swiftUIColor else {
                withAnimation { config.backgroundColor = .teal }
                return
            }
            withAnimation { config.backgroundColor = timerColor }
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
