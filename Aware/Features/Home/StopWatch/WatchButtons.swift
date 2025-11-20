//
//  WatchButtons.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import SwiftUI
import AwareData
import OSLog

private var logger = Logger(subsystem: "StopWatch", category: "WatchButtons")

struct WatchButtons: View {
    @Environment(\.appConfig) private var appConfig
    @Environment(AwarenessSession.self) private var awarenessSession

    private var timer: Timekeeper? { awarenessSession.activeTimer }
    
    var body: some View {
        VStack(spacing: 16) {
            if let timer = timer {
                HStack(spacing: 12) {
                    PlayPauseButton(
                        isRunning: timer.isRunning,
                        hasElapsedTime: timer.totalElapsedSeconds > 0,
                        onAction: {
                            logger.debug("Play/Pause tap")
                            if timer.isRunning {
                                awarenessSession.pauseTimer()
                            } else if timer.totalElapsedSeconds > 0 {
                                awarenessSession.resumeTimer()
                            } else {
                                // This shouldn't happen as timer creation is handled in QuickStart
                                logger.warning("Attempting to start timer from play button")
                            }
                        }
                    )
                    
                    // Stop Button (visible when timer is running or has elapsed time)
                    if timer.isRunning || timer.totalElapsedSeconds > 0 {
                        StopButton(
                            isRunning: timer.isRunning,
                            onAction: {
                                withAnimation(.stopWatch) {
                                    awarenessSession.stopTimer()
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Empty space to maintain layout
                Spacer()
                    .frame(height: 44)
            }
        }
        
        if timer == nil {
            Text("Start a timer when you’re ready to give this moment your attention.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .scale))
        }
    }
}

#Preview {
    WatchButtons()
}
