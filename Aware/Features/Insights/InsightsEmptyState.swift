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
        return switch store.currentTimeFrame {
        case .daily(let day):
            day.isInSameDay(as: .now) ?
            "No time tracked today" :
            "No time tracked that day"
        case .week(let week):
            week.isInSameDay(as: Date.now.startOfWeek) ?
            "No time tracked this week" :
            "No time tracked that week"
        case .month(let month):
            month.month == Date.now.month && month.year == Date.now.year ?
            "No time tracked this month" :
            "No time tracked that month"
        case .year(let year):
            year.year == Date.now.year ?
            "No time tracked this year" :
            "No time tracked that year"
        case .allTime: "No time tracked yet"
        }
    }
    
    private var descriptionText: String {
        return switch store.currentTimeFrame {
        case .daily(let day):
            day.isInSameDay(as: .now) ?
            "Be present with your time. Start a timer to see your day unfold" :
            "Nothing was recorded on this date"
        case .week(let week):
            week.isInSameDay(as: Date.now.startOfWeek) ?
            "Bring awareness to your days. Start your first timer this week" :
            "No intentional time was recorded during that week"
        case .month(let month):
            month.month == Date.now.month && month.year == Date.now.year ?
            "There's still time to make this month meaningful" :
            "No intentional time was recorded in that month"
        case .year(let year):
            year.year == Date.now.year ?
            "Every moment adds up. Start being aware of your time this year" :
            "No intentional time was recorded during that year"
        case .allTime: "Begin your first timer and give your time intention"
        }
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
        .animation(.spring(), value: store.currentTimeFrame)
    }
}
