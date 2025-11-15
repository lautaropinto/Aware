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
    
    @Query private var activeTimers: [Timekeeper]
    
    var timer: Timekeeper? {
        activeTimers.first
    }

    private var timerInterval: ClosedRange<Date>? {
        guard let timer = timer, timer.isRunning, let startTime = timer.startTime else { return nil }
        let adjustedStartTime = startTime.addingTimeInterval(-timer.totalElapsedSeconds)
        return adjustedStartTime...Date.distantFuture
    }

    private var displayTime: String {
        guard let timer = timer else { return "00:00" }

        if !timer.isRunning {
            return timer.formattedElapsedTime
        }

        // For running timers, we'll use the Text with timerInterval
        // This is just a fallback that shouldn't be used
        return timer.formattedElapsedTime
    }
    
    private var hasActiveTimer: Bool {
        timer != nil
    }
    
    public init() {
        let predicate = #Predicate<Timekeeper> { $0.endTime == nil }
        self._activeTimers = Query(filter: predicate)
    }
    
    public var body: some View {
        let _ = Self._printChanges()
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                if let timer = timer {
                    Text(timer.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Empty space to maintain layout
                    Spacer()
                        .frame(height: 44)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasActiveTimer)
            
            // Time Display
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
            .foregroundColor(hasActiveTimer ? (timer?.isRunning == true ? .primary : .secondary) : .secondary)
            .animation(.easeInOut(duration: 0.3), value: hasActiveTimer)
            
            // Control Buttons (shows when active)
            VStack(spacing: 16) {
                if let timer = timer {
                    HStack(spacing: 12) {
                        // Primary Action Button (Start/Pause/Resume)
                        PlayPauseButton(
                            isRunning: timer.isRunning,
                            hasElapsedTime: timer.totalElapsedSeconds > 0,
                            onAction: {
                                logger.debug("Play/Pause tap")
                                activityStore.timer = timer
                                appConfig.isTimerRunning = true
                                if let storedTimer = activityStore.timer {
                                    logger.debug("Activity stored name: \(storedTimer.name)")
                                }
                                if timer.isRunning {
                                    timer.pause()
                                    activityStore.updateLiveActivity(
                                        elapsedTime: timer.currentElapsedTime,
                                        intentAction: .pause
                                    )
                                } else if timer.totalElapsedSeconds > 0 {
                                    timer.resume()
                                    activityStore.updateLiveActivity(
                                        elapsedTime: timer.currentElapsedTime,
                                        intentAction: .resume
                                    )
                                } else {
                                    timer.start()
                                    activityStore.startLiveActivity(with: timer)
                                }
                            }
                        )
                        
                        // Stop Button (visible when timer is running or has elapsed time)
                        if timer.isRunning || timer.totalElapsedSeconds > 0 {
                            StopButton(
                                isRunning: timer.isRunning,
                                onAction: {
                                    withAnimation {
                                        appConfig.backgroundColor = .accentColor
                                        appConfig.isTimerRunning = false
                                    }
                                    timer.stop()
                                    NotificationCenter.default.post(name: .timerDidStop, object: nil)
                                    activityStore.endLiveActivity()
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timer.isRunning)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timer.totalElapsedSeconds > 0)
                } else {
                    // Empty space to maintain layout
                    Spacer()
                        .frame(height: 44)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasActiveTimer)
            
            // Disclaimer text (shows when empty)
            if timer == nil {
                Text("Start a timer when you’re ready to give this moment your attention.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .glassEffect(.clear, in: .containerRelative)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: hasActiveTimer)
        .onAppear() {
            onAppear()
        }
    }
    
    private func onAppear() {
        checkIfThereIsTimerRunning()
    }
    
    private func checkIfThereIsTimerRunning() {
        guard let timer else { return }
        
        appConfig.isTimerRunning = true
        activityStore.timer = timer
        logger.debug("Starting activity with timer: \(timer.formattedElapsedTime)")
        activityStore.startLiveActivity(with: timer)
    }
}
