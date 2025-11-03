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
    
    @State private var currentTime = Date()
    private let timeUpdateTimer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                Text(displayTime)
                    .font(timekeeper.isRunning ? .subheadline.bold() : .subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(timekeeper.isRunning ? .primary : .secondary)
                    .contentTransition(.numericText())
                    .animation(.spring, value: displayTime)
                
                if timekeeper.isRunning {
                    Text("Running")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        }
        .listRowBackground(
            ConcentricRectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
        )
        .onReceive(timeUpdateTimer) { _ in
            if let timekeeper = entry as? Timekeeper, timekeeper.isRunning {
                currentTime = Date()
            }
        }
    }
    
    private var displayTime: String {
        guard let timekeeper = entry as? Timekeeper else {
            return "00:00"
        }
        // Reference currentTime to ensure this property depends on it for running timers
        if timekeeper.isRunning {
            _ = currentTime
        }
        return timekeeper.formattedElapsedTime
    }
}
