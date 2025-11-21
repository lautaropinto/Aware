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
    @Environment(AwarenessSession.self) private var awarenessSession
    
    public var body: some View {
        VStack(spacing: 16) {
            WatchTitle()
            
            WatchTimer()
            
            WatchButtons()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 32.0)
                .stroke(.gray.gradient.opacity(0.32), lineWidth: 1.0)
                .fill(.ultraThinMaterial.opacity(0.24))
                .shadow(color: .gray.opacity(0.4), radius: 2.0, x: 0.0, y: 1)
        )
        .onAppear() {
            onAppear()
        }
    }
    
    private func onAppear() {
        checkIfThereIsTimerRunning()
    }

    private func checkIfThereIsTimerRunning() {
        awarenessSession.resumeIfNeeded()

        if let timer = awarenessSession.activeTimer {
            logger.debug("Resuming session with timer: \(timer.formattedElapsedTime)")
        }
    }
}
