//
//  WorkoutRow.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/11/25.
//

import SwiftUI
import SwiftData
import AwareData
import HealthKit

struct WorkoutRow: View {
    let entry: any TimelineEntry

    var body: some View {
        HStack {
            HStack {
                TagIconView(color: entry.swiftUIColor, icon: entry.image)
                    .scaleEffect(0.86)

                VStack(alignment: .leading, spacing: 4.0) {
                    Text(entry.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let startTime = entry.startTime,
                       let endTime = entry.endTime {
                        Text("\(startTime.formattedTime) - \(endTime.formattedTime)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .rounded()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.duration.formattedElapsedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .rounded()

                HStack {
                    Text("Imported from Health")
                        .font(.caption2.italic())
                        .foregroundStyle(.secondary)
                    Image(systemName: "heart.fill")
                        .imageScale(.small)
                        .foregroundStyle(.pink.gradient)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(entry.swiftUIColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(entry.swiftUIColor.gradient.opacity(0.64), lineWidth: 1.2)
        )
    }
}

#Preview {
    // Create a mock DailyWorkoutEntry for preview
    let mockStartDate = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    let mockEndDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()

    List {
        WorkoutRow(entry: PreviewWorkoutEntry(
            startTime: mockStartDate,
            endTime: mockEndDate,
            name: "2 Workouts"
        ))
    }
}

// Preview helper
private struct PreviewWorkoutEntry: TimelineEntry {
    let id = UUID()
    let startTime: Date?
    let endTime: Date?
    let name: String

    var creationDate: Date { startTime ?? Date() }
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }
    var swiftUIColor: SwiftUI.Color { .orange }
    var image: String { "figure.mixed.cardio" }
    var type: TimelineEntryType { .workout }
}
