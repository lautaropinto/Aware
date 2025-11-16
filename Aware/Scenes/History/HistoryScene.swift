//
//  HistoryScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import HealthKit
import OSLog

private var logger = Logger(subsystem: "HistoryScene", category: "Scene")


struct HistoryScene: View {
    @Environment(Storage.self) private var storage

    @State private var history = History()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HistoryFilter()

                HistoryList()
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ManualEntryButton()
                }
            }
            .environment(history)
            .onChange(of: storage.timers) { _, newTimers in
                updateHistoryData()
            }
            .onChange(of: storage.sleepData) { _, newSleepData in
                updateHistoryData()
            }
            .onChange(of: storage.workoutData) { _, newWorkoutData in
                updateHistoryData()
            }
            .onAppear {
                updateHistoryData()
            }
        }
    }

    private func updateHistoryData() {
        history.processData(
            timers: storage.timers,
            sleepData: storage.sleepData,
            workoutData: storage.workoutData
        )
    }
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
