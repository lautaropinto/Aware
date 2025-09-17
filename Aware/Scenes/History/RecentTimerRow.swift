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
    let timekeeper: Timekeeper
    
    @State private var currentTime = Date()
    private let timeUpdateTimer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timekeeper.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let tag = timekeeper.tag {
                    Text(tag.name)
                        .font(.caption)
                        .foregroundColor(tag.swiftUIColor)
                }
            }
            
            Spacer()
            
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
        .listRowBackground(Color.clear)
        .onReceive(timeUpdateTimer) { _ in
            if timekeeper.isRunning {
                currentTime = Date()
            }
        }
    }
    
    private var displayTime: String {
        // Reference currentTime to ensure this property depends on it for running timers
        if timekeeper.isRunning {
            _ = currentTime
        }
        return timekeeper.formattedElapsedTime
    }
}
