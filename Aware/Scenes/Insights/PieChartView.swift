//
//  InsightsPieChart.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI
import Charts
import AwareData

struct PieChartView: View {
    let data: [TagInsightData]
    let totalTime: TimeInterval

    @Environment(InsightStore.self) private var store

    @State private var hasAppeared = false
    @State private var chartProgress: Double = 0.0
    @State private var hasEverAppeared = false

    private var isDailyTimeFrame: Bool {
        switch store.currentTimeFrame {
        case .daily:
            return true
        default:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            if data.isEmpty {
                InsightsEmptyState()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .opacity(hasAppeared ? 1.0 : 0.0)
            } else {
                ChartView()
                    .animation(.spring(), value: data.map(\.id))

                LegendView()
            }
        }
        .onAppear {
            if !hasEverAppeared {
                hasEverAppeared = true
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    hasAppeared = true
                }
                withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
                    chartProgress = 1.0
                }
            } else {
                // Instant appearance for subsequent visits
                hasAppeared = true
                chartProgress = 1.0
            }
        }
    }

    @ViewBuilder
    private func ChartView() -> some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Time", item.totalTime * chartProgress),
                innerRadius: .ratio(totalTime > 3600 ? 0.6 : 0.48),
                outerRadius: .ratio(totalTime > 3600 ? 0.9 : 0.8),
                angularInset: 2
            )
            .foregroundStyle(item.tag.swiftUIColor.gradient)
            .opacity(0.8)
        }
        .frame(height: 300)
        .overlay {
            CenterChartOverlayView()
        }
    }

    @ViewBuilder private func LegendView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let sortedData = data.prefix(5).sorted(by: { $0.percentage > $1.percentage })
            ForEach(Array(sortedData.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    if item.tag.name == "Untracked" {
                        UntrackedTimeIconView()
                            .scaleEffect(0.8)
                    } else {
                        TagIconView(tag: item.tag)
                            .scaleEffect(0.8)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.tag.name)
                                .font(.body.weight(.medium))
                                .foregroundColor(.primary)

                            HStack(alignment: .center) {
                                Text(item.totalTime.formattedElapsedTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .contentTransition(.numericText())

                                // Show average time for non-daily timeframes
                                if !isDailyTimeFrame && item.shouldShowAverage {
                                    Text("• \(item.averageTime.compactFormattedTime) avg per session")
                                        .font(.caption)
                                        .italic()
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .contentTransition(.numericText())
                                }
                            }
                        }

                        Spacer()

                        Text("\(Int(item.percentage))%")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                    }
                }
            }

            if data.count > 5 {
                HStack {
                    Circle()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 12, height: 12)

                    Text("and \(data.count - 5) more...")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder private func CenterChartOverlayView() -> some View {
        VStack(spacing: 4) {
            let wording = "All day time"
            let timeText = (totalTime * chartProgress).formattedElapsedTime
            Text(store.showUntrackedTime ? wording : timeText)
                .font(store.showUntrackedTime ? .title3 : .title)
                .bold()
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            if !store.showUntrackedTime {
                Text("Total Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let sampleTag1 = Tag(name: "Working", color: "#FF6B6B")
    let sampleTag2 = Tag(name: "Learning", color: "#4ECDC4")
    let sampleTag3 = Tag(name: "Exercise", color: "#45B7D1")

    let sampleData = [
        TagInsightData(tag: sampleTag1, totalTime: 7200, percentage: 60.0, sessionCount: 0),
        TagInsightData(tag: sampleTag2, totalTime: 3600, percentage: 30.0, sessionCount: 0),
        TagInsightData(tag: sampleTag3, totalTime: 1200, percentage: 10.0, sessionCount: 0)
    ]

    PieChartView(data: sampleData, totalTime: 12000)
        .padding()
}

struct UntrackedTimeIconView: View {
    var body: some View {
        Image(systemName: "clock.fill")
            .imageScale(.small)
            .foregroundStyle(Color.primary)
            .padding(8.0)
            .background(
                Circle()
                    .fill(Color.gray.gradient)
                    .frame(width: 32.0, height: 32.0)
            )
    }
}
