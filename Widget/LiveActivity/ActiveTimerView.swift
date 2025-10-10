//
//  ActiveTimerView.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/22/25.
//

import SwiftUI
import ActivityKit
import WidgetKit
import AwareData
import AwareUI
import AppIntents
import SwiftData

struct ActiveTimerView: View {
    @Query var tags: [Tag]
    
    let context: ActivityViewContext<TimerAttributes>
    
    @Environment(\.activityFamily) private var activityFamily
    
    var body: some View {
        let timer = context.attributes.timer
        
        switch activityFamily {
        case .small:
            SmallContent(timer: timer)
        case .medium:
            MediumContent(timer: timer)
        @unknown default:
            MediumContent(timer: timer)
        }
    }
    
    @ViewBuilder private func SmallContent(timer: Timekeeper) -> some View {
        VStack(spacing: 8.0) {
            HStack(spacing: 8.0) {
                Image("aware")
                
                if let tag = timer.mainTag {
                    Text("\(tag.name)")
                        .bold()
                }
                Spacer()
            }
            .padding(.leading, 6.0)

            HStack {
                if context.state.intentAction == .resume {
                    CountText(timeInterval: context.state.timerInterval)
                        .font(context.state.totalElapsedSeconds > 3600 ? .body : .title3)
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                        .foregroundColor(!context.isStale ? .primary : .secondary)
                        .contentTransition(.numericText())
                } else {
                    Text(context.state.totalElapsedSeconds.formattedElapsedTime)
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
                
                if !context.isStale {
                    HStack(spacing: 0.0) {
                        StopButton(displayText: false)
                            .scaleEffect(0.8)
                        PauseResumeButton(displayText: false)
                            .scaleEffect(0.8)
                    }
                } else {
                    Text("Finished")
                        .bold()
                        .foregroundStyle(.red.opacity(0.6))
                }
            }
        }
        .padding(8.0)
        .activityBackgroundTint(context.attributes.timer.mainTag!.swiftUIColor.opacity(0.1))
    }
    
    @ViewBuilder private func MediumContent(timer: Timekeeper) -> some View {
        VStack(spacing: 8.0) {
            HStack {
                Image("aware")
                
                Text("\(context.attributes.timer.name)")
                    .font(.headline.bold())
            }
            
            if context.state.intentAction == .resume {
                CountText(timeInterval: context.state.timerInterval)
                    .font(.largeTitle)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundColor(!context.isStale ? .primary : .secondary)
                    .contentTransition(.numericText())
            } else {
                Text(context.state.totalElapsedSeconds.formattedElapsedTime)
                    .font(.largeTitle)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }
            
            if !context.isStale {
                HStack {
                    StopButton()
                    PauseResumeButton()
                }
            } else {
                Text("Finished")
                    .font(.headline)
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding()
        .onAppear {
            print("tags count from widget:", tags)
        }
    }
    
    @ViewBuilder
    private func StopButton(displayText: Bool = true) -> some View {
        let intent = StopWatchLiveIntent(
            timerID: context.attributes.timer.id.uuidString,
            action: "stop"
        )
        
        Toggle(isOn: context.state.isLoading, intent: intent) {
            
        }
        .toggleStyle(
            CustomToggleStyle(
                image: "stop.fill",
                displayText: displayText,
                text: "Stop",
                backgroundColor: .red
            )
        )
    }
    
    @ViewBuilder
    private func PauseResumeButton(displayText: Bool = true) -> some View {
        let isRunning = context.state.intentAction == .resume
        
        let intent = StopWatchLiveIntent(
            timerID: context.attributes.timer.id.uuidString,
            action: isRunning ? "pause" : "resume"
        )
        
        Toggle(isOn: context.state.isLoading, intent: intent) {
            
        }
        .toggleStyle(
            CustomToggleStyle(
                image: isRunning ? "pause.fill" : "play.fill",
                displayText: displayText,
                text: isRunning ? "Pause" : "Resume",
                backgroundColor: isRunning ? .yellow : .green
            )
        )
    }
}

/// Workaround to place a loader after a tap.
private struct CustomToggleStyle: ToggleStyle {
    let image: String
    let displayText: Bool
    let text: String
    let backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            if configuration.isOn {
                Image(systemName: "progress.indicator")
                    .foregroundStyle(.gray.gradient)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: image)
                    
                    if displayText {
                        Text(text)
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    backgroundColor.opacity(0.8),
                    in: .capsule
                )
            }
        }
        .buttonStyle(.plain)
    }
}
