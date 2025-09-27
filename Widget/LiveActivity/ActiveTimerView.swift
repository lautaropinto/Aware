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
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        let timer = context.attributes.timer
        
        VStack(spacing: 8.0) {
            HStack {
                if let tag = timer.mainTag {
                    TagIconView(tag: tag)
                }
                
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
    private func StopButton() -> some View {
        
        Button(
            intent: StopWatchLiveIntent(
                timerID: context.attributes.timer.id.uuidString,
                action: "stop"
            ), label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.8), in: .capsule)
            }
        )
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func PauseResumeButton() -> some View {
        let isRunning = context.state.intentAction == .resume
        Button(
            intent: StopWatchLiveIntent(
                timerID: context.attributes.timer.id.uuidString,
                action: isRunning ? "pause" : "resume"
            ), label: {
                HStack(spacing: 6) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    Text(isRunning ? "Pause" : "Resume")
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isRunning ? .yellow.opacity(0.8) : .green.opacity(0.8), in: .capsule)
            }
        )
        .buttonStyle(.plain)
    }
}
