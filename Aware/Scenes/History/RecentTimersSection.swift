//
//  RecentTimersSection.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData

struct RecentTimersSection: View {
    let timers: [Timekeeper]
    let modelContext: ModelContext
    let onTimerDeleted: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Timers")
                .font(.headline)
                .fontWeight(.semibold)
            
            List {
                ForEach(timers, id: \.id) { timekeeper in
                    RecentTimerRow(timekeeper: timekeeper)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                deleteTimer(timekeeper)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .frame(height: CGFloat(timers.count * 70)) // Approximate height per row
            .scrollDisabled(true) // Disable list scrolling since we're in a ScrollView
        }
    }
    
    private func deleteTimer(_ timer: Timekeeper) {
        withAnimation {
            modelContext.delete(timer)
            try? modelContext.save()
            onTimerDeleted()
        }
    }
}
