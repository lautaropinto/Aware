//
//  InsightsEmptyState.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/3/25.
//

import SwiftUI

struct InsightsEmptyState: View {
    @Environment(InsightStore.self) var store
    
    private var titleText: String {
        let isToday = Calendar.current.isDate(store.selectedDate, inSameDayAs: Date.now)
        return isToday ? "No time tracked today" : "No time tracked that day"
    }
    
    private var descriptionText: String {
        let isToday = Calendar.current.isDate(store.selectedDate, inSameDayAs: Date.now)
        return isToday ?
            "Be present with your time. Start a timer to see your day unfold" :
            "Nothing was recorded on this date"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("")
                Spacer()
            }
            Image(systemName: "chart.pie")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(titleText)
                .font(.title2.bold())
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            Text(descriptionText)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .frame(height: 56)
        }
        .rounded()
        .frame(height: 320)
        .animation(.spring(), value: store.selectedDate)
    }
}
