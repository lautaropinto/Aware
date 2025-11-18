//
//  RecentTimerRow.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData

struct RecentTimerRow: View {
    let entry: any TimelineEntry

    private var timerInterval: ClosedRange<Date>? {
        guard let timekeeper = entry as? Timekeeper,
              timekeeper.isRunning,
              let startTime = timekeeper.startTime else { return nil }
        let adjustedStartTime = startTime.addingTimeInterval(-timekeeper.totalElapsedSeconds)
        return adjustedStartTime...Date.distantFuture
    }
    
    var body: some View {
        HStack {
            HStack() {
                TagIconView(color: entry.swiftUIColor, icon: entry.image)
                    .scaleEffect(0.86)
                
                VStack(alignment: .leading, spacing: 2.0) {
                    
                    Text(entry.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let timekeeper = entry as? Timekeeper, !timekeeper.isRunning,
                       let endTime = timekeeper.endTime {
                        Text("\(timekeeper.creationDate.formattedTime) - \(endTime.formattedTime)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let timekeeper = entry as? Timekeeper {
               VStack(alignment: .trailing, spacing: 4) {
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
                .font(timekeeper.isRunning ? .subheadline.bold() : .subheadline)
                .fontWeight(.medium)
                .foregroundColor(timekeeper.isRunning ? .primary : .secondary)
                
                if timekeeper.isRunning {
                    Text("Running")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.gradient.opacity(0.32), lineWidth: 1.0)
                .fill(.ultraThinMaterial.opacity(0.36))
                .shadow(color: .gray.opacity(0.46), radius: 2.0, x: 0.0, y: 1)
        )
    }

    private var displayTime: String {
        guard let timekeeper = entry as? Timekeeper else {
            return "00:00"
        }
        // For non-running timers, use the formatted elapsed time
        return timekeeper.formattedElapsedTime
    }
}
