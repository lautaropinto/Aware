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
import AwareUI

private var logger = Logger(subsystem: "HistoryScene", category: "Scene")


struct HistoryScene: View {
    @Environment(Storage.self) private var storage
    @Environment(\.appConfig) private var appConfig

    @State private var history = HistoryStore()

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
            .applyBackgroundGradient()
            .onChange(of: storage.changeToken) { _, _ in
                history.refreshData()
            }
            .onAppear {
                history.configure(storage: storage, healthKitManager: HealthKitManager.shared)
                history.refreshData()
                Tracker.signal("history.viewed")
            }
        }
    }

    // updateHistoryData is no longer needed - HistoryStore handles its own data loading
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}
