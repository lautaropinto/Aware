//
//  ActiveTimerWidget.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/22/25.
//

import SwiftUI
import WidgetKit
import ActivityKit
import AwareData
import AwareUI

struct ActiveTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            ActiveTimerView(context: context)
                .activityBackgroundTint(context.attributes.timer.mainTag!.swiftUIColor.opacity(0.1))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        TagIconView(tag: context.attributes.timer.mainTag!)
                        
                        Text("\(context.attributes.timer.name):")
                            .fixedSize(horizontal: true, vertical: true)
                            .bold()
                    }
                    .padding(.top)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.intentAction == .resume {
                        CountText(timeInterval: context.state.timerInterval)
                            .font(.title2)
                            .fontDesign(.monospaced)
                            .contentTransition(.numericText())
                            .padding(.top)
                    } else {
                        Text(context.state.totalElapsedSeconds.formattedElapsedTime)
                            .font(.title2)
                            .fontDesign(.monospaced)
                            .contentTransition(.numericText())
                            .padding(.top)
                    }
                }
            } compactLeading: {
                let tag = context.attributes.timer.mainTag!
                Image(systemName: tag.image)
                    .foregroundStyle(tag.swiftUIColor.gradient)
            } compactTrailing: {
                if context.state.intentAction == .resume {
                    CountText(timeInterval: context.state.timerInterval)
                } else {
                    Text(context.state.totalElapsedSeconds.formattedElapsedTime)
                        .fontDesign(.monospaced)
                        .contentTransition(.numericText())
                }
            } minimal: {
                let tag = context.attributes.timer.mainTag!
                Image(systemName: tag.image)
                    .foregroundStyle(tag.swiftUIColor.gradient)
                    
            }
        }
    }
}


extension TimeInterval {
    public var formattedElapsedTime: String {
        let time = self
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
