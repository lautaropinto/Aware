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

    @State private var hasAppeared = false
    @State private var chartProgress: Double = 0.0
    @State private var hasEverAppeared = false

    var body: some View {
        VStack(spacing: 24) {
            if data.isEmpty {
                InsightsEmptyState()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .opacity(hasAppeared ? 1.0 : 0.0)
            } else {
                pieChartView
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .opacity(hasAppeared ? 1.0 : 0.0)

                legendView
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: data.map(\.id))
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

    private var pieChartView: some View {
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
            VStack(spacing: 4) {
                Text((totalTime * chartProgress).formattedElapsedTime)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                Text("Total Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totalTime)
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(data.prefix(5).enumerated()), id: \.element.id) { index, item in
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

                            Text(item.totalTime.formattedElapsedTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
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
}

#Preview {
    let sampleTag1 = Tag(name: "Working", color: "#FF6B6B")
    let sampleTag2 = Tag(name: "Learning", color: "#4ECDC4")
    let sampleTag3 = Tag(name: "Exercise", color: "#45B7D1")

    let sampleData = [
        TagInsightData(tag: sampleTag1, totalTime: 7200, percentage: 60.0),
        TagInsightData(tag: sampleTag2, totalTime: 3600, percentage: 30.0),
        TagInsightData(tag: sampleTag3, totalTime: 1200, percentage: 10.0)
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
