//
//  UnifiedTimerView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/22/25.
//

import SwiftUI
import AwareData
import OSLog

private var logger = Logger(subsystem: "Aware", category: "iOS StopWatch")

public struct StopWatch: View {
    let timer: Timekeeper?
    let onStateChange: () -> Void
    
    public init(timer: Timekeeper?,
                onStateChange: @escaping () -> Void) {
        self.timer = timer
        self.onStateChange = onStateChange
    }
    
    @Environment(\.appConfig) private var appConfig
    @Environment(ActivityStore.self) private var activityStore
    
    @State private var currentTime = Date()
    
    private let timeUpdateTimer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Computed property that forces recalculation when currentTime changes
    private var displayTime: String {
        guard let timer = timer else { return "00:00" }
        
        // Reference currentTime to ensure this property depends on it
        _ = currentTime
        
        if timer.isRunning {
            let elapsed = timer.totalElapsedSeconds + (timer.startTime?.timeIntervalSinceNow ?? 0) * -1
            let hours = Int(elapsed) / 3600
            let minutes = Int(elapsed) % 3600 / 60
            let seconds = Int(elapsed) % 60
            
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        } else {
            return timer.formattedElapsedTime
        }
    }
    
    private var hasActiveTimer: Bool {
        timer != nil
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Timer Info (shows when active)
            VStack(spacing: 8) {
                if let timer = timer {
                    Text(timer.name)
                        #if os(watchOS)
                        .font(.headline)
                        #else
                        .font(.title2)
                        #endif
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
            Text(displayTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(hasActiveTimer ? (timer?.isRunning == true ? .primary : .secondary) : .secondary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayTime)
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
                                onStateChange()
                            }
                        )
                        
                        // Stop Button (visible when timer is running or has elapsed time)
                        if timer.isRunning || timer.totalElapsedSeconds > 0 {
                            StopButton(
                                isRunning: timer.isRunning,
                                onAction: {
                                    withAnimation {
                                        appConfig.backgroundColor = .accentColor
                                    }
                                    timer.stop()
                                    activityStore.endLiveActivity()
                                    onStateChange()
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
        #if os(watchOS)
        .padding(12)
        #else
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .glassEffect(.clear, in: .containerRelative)
        #endif
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: hasActiveTimer)
        .onReceive(timeUpdateTimer) { _ in
//            if let timer {
//                activityStore.updateLiveActivity(elapsedTime: timer.currentElapsedTime)
//            }
            
            currentTime = Date()
        }
    }
}
