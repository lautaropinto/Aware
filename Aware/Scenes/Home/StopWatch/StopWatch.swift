//
//  UnifiedTimerView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/22/25.
//

import SwiftUI
import SwiftData
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "iOS StopWatch")

public struct StopWatch: View {
    @Environment(\.appConfig) private var appConfig
    @Environment(LiveActivityStore.self) private var activityStore
    @Environment(Storage.self) private var storage
    
    public var body: some View {
        VStack(spacing: 16) {
            WatchTitle()
            
            WatchTimer()
            
            WatchButtons()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .glassEffect(.clear, in: .containerRelative)
        .onAppear() {
            onAppear()
        }
    }
    
    private func onAppear() {
        checkIfThereIsTimerRunning()
    }
    
    private func checkIfThereIsTimerRunning() {
        guard let timer = storage.timer else { return }
        
        appConfig.isTimerRunning = true
        appConfig.updateColor(timer.swiftUIColor)
        activityStore.timer = timer
        logger.debug("Starting activity with timer: \(timer.formattedElapsedTime)")
        activityStore.startLiveActivity(with: timer)
    }
}
