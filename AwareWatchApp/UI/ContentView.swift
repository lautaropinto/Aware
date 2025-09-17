//
//  ContentView.swift
//  AwareWatch Watch App
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI

struct ContentView: View {
    @Query private var timers: [Timekeeper]
    
    @State private var currentTimer: Timekeeper?
    
    var body: some View {
        VStack {
            if let currentTimer = currentTimer {
                UnifiedTimerView(
                    timer: currentTimer,
                    onStateChange: refreshCurrentTimer
                )
                
            } else {
                TimerList(currentTimer: $currentTimer)
            }
        }
        .onAppear {
            findCurrentTimer()
        }
        .applyBackgroundGradient()
    }
    
    private func findCurrentTimer() {
        // Find the most recent timer that's either running or paused (has elapsed time but no end time)
        currentTimer = timers.first { timer in
            timer.isRunning || (timer.totalElapsedSeconds > 0 && timer.endTime == nil)
        }
    }
    
    private func refreshCurrentTimer() {
        // Find the most recent timer that's either running or paused (has elapsed time but no end time)
        currentTimer = timers.first { timer in
            timer.isRunning || (timer.totalElapsedSeconds > 0 && timer.endTime == nil)
        }
    }
}

#Preview(traits: .defaultTagsSwiftData) {
    ContentView()
}
