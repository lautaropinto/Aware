//
//  SleepRow.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import SwiftUI
import SwiftData
import AwareData
import HealthKit

struct SleepRow: View {
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
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.duration.formattedElapsedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
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
        .listRowBackground(
            ConcentricRectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
        )
    }
}

#Preview {
    // Create a mock HKCategorySample for preview
    let mockStartDate = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    let mockEndDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()

    List {
        SleepRow(entry: PreviewSleepEntry(
            startTime: mockStartDate,
            endTime: mockEndDate,
            name: "Core Sleep"
        ))
    }
}

// Preview helper
private struct PreviewSleepEntry: TimelineEntry {
    let id = UUID()
    let startTime: Date?
    let endTime: Date?
    let name: String

    var creationDate: Date { startTime ?? Date() }
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }
    var swiftUIColor: SwiftUI.Color { .blue }
    var image: String { "moon.fill" }
    var type: TimelineEntryType { .sleep }
}
