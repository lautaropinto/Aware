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
    @Environment(LiveActivityStore.self) private var liveActivityStore
    @Environment(Storage.self) private var storage
    
    private var timer: Timekeeper? { storage.timer }
    
    var body: some View {
        VStack(spacing: 16) {
            if let timer = timer {
                HStack(spacing: 12) {
                    PlayPauseButton(
                        isRunning: timer.isRunning,
                        hasElapsedTime: timer.totalElapsedSeconds > 0,
                        onAction: {
                            logger.debug("Play/Pause tap")
                            liveActivityStore.timer = timer
                            appConfig.isTimerRunning = true
                            if let storedTimer = liveActivityStore.timer {
                                logger.debug("Activity stored name: \(storedTimer.name)")
                            }
                            if timer.isRunning {
                                timer.pause()
                                liveActivityStore.updateLiveActivity(
                                    elapsedTime: timer.currentElapsedTime,
                                    intentAction: .pause
                                )
                            } else if timer.totalElapsedSeconds > 0 {
                                timer.resume()
                                liveActivityStore.updateLiveActivity(
                                    elapsedTime: timer.currentElapsedTime,
                                    intentAction: .resume
                                )
                            } else {
                                timer.start()
                                liveActivityStore.startLiveActivity(with: timer)
                            }
                        }
                    )
                    
                    // Stop Button (visible when timer is running or has elapsed time)
                    if timer.isRunning || timer.totalElapsedSeconds > 0 {
                        StopButton(
                            isRunning: timer.isRunning,
                            onAction: {
                                withAnimation(.stopWatch) {
                                    appConfig.backgroundColor = .accentColor
                                    appConfig.isTimerRunning = false
                                    timer.stop()
                                    storage.timer = nil
                                    NotificationCenter.default.post(name: .timerDidStop, object: nil)
                                    liveActivityStore.endLiveActivity()
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
