//
//  WatchTimer.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import SwiftUI
import AwareData

struct WatchTimer: View {
    @Environment(Storage.self) private var storage
    
    private var timer: Timekeeper? { storage.timer }
    
    private var timerInterval: ClosedRange<Date>? {
        guard let timer = timer, timer.isRunning, let startTime = timer.startTime else { return nil }
        let adjustedStartTime = startTime.addingTimeInterval(-timer.totalElapsedSeconds)
        
        return adjustedStartTime...Date.distantFuture
    }

    private var displayTime: String {
        guard let timer = timer else { return "00:00" }

        return timer.formattedElapsedTime
    }
    
    var body: some View {
        Group {
            if let timerInterval = timerInterval {
                Text(timerInterval: timerInterval, countsDown: false)
                    .contentTransition(.numericText())
                    .fontDesign(.monospaced)
            } else {
                Text(displayTime)
                    .contentTransition(.numericText())
            }
        }
        .font(.system(size: 48, weight: .bold, design: .monospaced))
    }
}

#Preview {
    WatchTimer()
}
