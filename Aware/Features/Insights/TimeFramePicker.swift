//
//  TimeFramePicker.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//  Simplified to daily-only by Claude on 11/20/25.
//

import SwiftUI

struct TimeFramePicker: View {
    @Binding var selectedDayDate: Date
    @Binding var showUntrackedTime: Bool

    @State private var showingDateSelector = false

    var body: some View {
        HStack {
            // Current date display (tappable)
            Button(action: {
                showingDateSelector = true
            }) {
                HStack(spacing: 6) {
                    Text(selectedDayDate.formattedDay)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Untracked time toggle
            UntrackedTimeToggle()
        }
        .sheet(isPresented: $showingDateSelector) {
            DateSelectorSheet()
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Untracked Time Toggle
extension TimeFramePicker {
    @ViewBuilder
    private func UntrackedTimeToggle() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showUntrackedTime.toggle()
                UserDefaults.standard.set(showUntrackedTime, forKey: .UserDefault.showUntrackedTime)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: showUntrackedTime ? "eye.fill" : "eye.slash.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Untracked")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(showUntrackedTime ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(showUntrackedTime ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Selector Sheet
extension TimeFramePicker {
    @ViewBuilder
    private func DateSelectorSheet() -> some View {
        VStack(spacing: 20) {
            Text("Select day")
                .font(.title2).bold()
                .fontDesign(.rounded)
                .padding(.top, 20)

            CustomDayPicker(selectedDay: $selectedDayDate)

            Spacer()

            Button("Done") {
                showingDateSelector = false
            }
            .buttonStyle(DefaultBigButton(color: .accent))
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Custom Day Picker
struct CustomDayPicker: View {
    @Binding var selectedDay: Date

    var body: some View {
        Picker("Select Day", selection: $selectedDay) {
            ForEach(availableDays, id: \.self) { dayDate in
                Text(displayText(for: dayDate))
                    .tag(dayDate)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }

    private func displayText(for dayDate: Date) -> String {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        if calendar.isDate(dayDate, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(dayDate, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            return dayDate.formattedDay
        }
    }

    private var availableDays: [Date] {
        var days: [Date] = []
        let calendar = Calendar.current

        // Generate days from 3 months ago to current day (no future days)
        let startDate = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let endDate = Date()

        var currentDate = startDate.startOfDay
        while currentDate <= endDate.startOfDay {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days.reversed() // Most recent first, oldest at bottom
    }
}

#Preview {
    @Previewable @State var selectedDayDate: Date = Date()
    @Previewable @State var showUntrackedTime: Bool = false

    VStack(spacing: 20) {
        TimeFramePicker(
            selectedDayDate: $selectedDayDate,
            showUntrackedTime: $showUntrackedTime
        )

        Text("Selected: \(selectedDayDate.formattedDay)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
