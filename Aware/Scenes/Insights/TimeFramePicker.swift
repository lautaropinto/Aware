//
//  TimeFramePicker.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI

struct TimeFramePicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    @Binding var selectedWeekDate: Date
    @Binding var selectedMonthDate: Date
    @Binding var selectedYearDate: Date
    let availableTimeFrames: [TimeFrame]

    @State private var showingPeriodSelector = false
    @State private var hasAppeared = false
    @State private var hasEverAppeared = false

    init(
        selectedTimeFrame: Binding<TimeFrame>,
        selectedWeekDate: Binding<Date>,
        selectedMonthDate: Binding<Date>,
        selectedYearDate: Binding<Date>,
        availableTimeFrames: [TimeFrame] = TimeFrame.allCases
    ) {
        self._selectedTimeFrame = selectedTimeFrame
        self._selectedWeekDate = selectedWeekDate
        self._selectedMonthDate = selectedMonthDate
        self._selectedYearDate = selectedYearDate
        self.availableTimeFrames = availableTimeFrames
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segmented picker for timeframe type
            TimeFrameTypePickerView()
                .opacity(hasAppeared ? 1.0 : 0.0)
                .scaleEffect(hasAppeared ? 1.0 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)

            // Date navigation controls
            if selectedTimeFrame != .allTime {
                DateNavigationView()
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
            }
        }
        .onAppear {
            if !hasEverAppeared {
                hasEverAppeared = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
            } else {
                // Instant appearance for subsequent visits
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingPeriodSelector) {
            PeriodSelectorSheet()
                .presentationDetents([.fraction(0.4), .medium])
                .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - TimeFrame Type Picker
extension TimeFramePicker {
    @ViewBuilder
    private func TimeFrameTypePickerView() -> some View {
        Picker("Time Frame Type", selection: Binding(
            get: { timeFrameType },
            set: { newType in
                switch newType {
                case "week":
                    selectedTimeFrame = .week(selectedWeekDate)
                case "month":
                    selectedTimeFrame = .month(selectedMonthDate)
                case "year":
                    selectedTimeFrame = .year(selectedYearDate)
                case "allTime":
                    selectedTimeFrame = .allTime
                default:
                    break
                }
            }
        )) {
            Text("Week").tag("week")
            Text("Month").tag("month")
            Text("Year").tag("year")
            Text("All Time").tag("allTime")
        }
        .pickerStyle(.segmented)
    }

    private var timeFrameType: String {
        switch selectedTimeFrame {
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        case .allTime:
            return "allTime"
        }
    }
}

// MARK: - Date Navigation
extension TimeFramePicker {
    @ViewBuilder
    private func DateNavigationView() -> some View {
        // Current period display (tappable)
        Button(action: {
            showingPeriodSelector = true
        }) {
            HStack(spacing: 6) {
                Text(selectedTimeFrame.displayName)
                    .bold()
                    .fontDesign(.rounded)
                    .contentTransition(.numericText())
                    .animation(.spring, value: selectedTimeFrame.id.hashValue)
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func updatePersistentDates(for timeFrame: TimeFrame) {
        switch timeFrame {
        case .week(let date):
            selectedWeekDate = date
        case .month(let date):
            selectedMonthDate = date
        case .year(let date):
            selectedYearDate = date
        case .allTime:
            break
        }
    }
}

// MARK: - Period Selector Sheet
extension TimeFramePicker {
    @ViewBuilder
    private func PeriodSelectorSheet() -> some View {
        VStack(spacing: 0) {
            // Header with title
            VStack(spacing: 20) {
                Text(sheetTitle)
                    .font(.title2).bold()
                    .fontDesign(.rounded)
                    .padding(.top, 20)

                switch selectedTimeFrame {
                case .week:
                    WeekDatePicker()
                case .month:
                    MonthDatePicker()
                case .year:
                    YearDatePicker()
                case .allTime:
                    EmptyView()
                }
            }

            Spacer()

            // Done button at bottom
            Button("Done") {
                showingPeriodSelector = false
            }
            .buttonStyle(DefaultBigButton(color: .accent))
            .padding(.horizontal, 20)
        }
    }

    private var sheetTitle: String {
        switch selectedTimeFrame {
        case .week:
            return "Select week"
        case .month:
            return "Select month"
        case .year:
            return "Select year"
        case .allTime:
            return ""
        }
    }
}

// MARK: - Custom Date Pickers
extension TimeFramePicker {
    @ViewBuilder
    private func WeekDatePicker() -> some View {
        CustomWeekPicker(
            selectedWeek: Binding(
                get: { currentWeekDate },
                set: { newDate in
                    selectedWeekDate = newDate
                    selectedTimeFrame = .week(newDate)
                }
            )
        )
    }

    @ViewBuilder
    private func MonthDatePicker() -> some View {
        CustomMonthPicker(
            selectedMonth: Binding(
                get: { currentMonthDate },
                set: { newDate in
                    selectedMonthDate = newDate
                    selectedTimeFrame = .month(newDate)
                }
            )
        )
    }

    @ViewBuilder
    private func YearDatePicker() -> some View {
        CustomYearPicker(
            selectedYear: Binding(
                get: { currentYearDate },
                set: { newDate in
                    selectedYearDate = newDate
                    selectedTimeFrame = .year(newDate)
                }
            )
        )
    }

    private var currentWeekDate: Date {
        switch selectedTimeFrame {
        case .week(let date):
            return date
        default:
            return selectedWeekDate
        }
    }

    private var currentMonthDate: Date {
        switch selectedTimeFrame {
        case .month(let date):
            return date
        default:
            return selectedMonthDate
        }
    }

    private var currentYearDate: Date {
        switch selectedTimeFrame {
        case .year(let date):
            return date
        default:
            return selectedYearDate
        }
    }
}

// MARK: - Custom Week Picker
struct CustomWeekPicker: View {
    @Binding var selectedWeek: Date

    var body: some View {
        Picker("Select Week", selection: $selectedWeek) {
            ForEach(availableWeeks, id: \.self) { weekDate in
                Text(displayText(for: weekDate))
                    .tag(weekDate)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }

    private func displayText(for weekDate: Date) -> String {
        let calendar = Calendar.current
        let today = Date()
        let thisWeekStart = today.startOfWeek
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart

        if weekDate == thisWeekStart {
            return "This week"
        } else if weekDate == lastWeekStart {
            return "Last week"
        } else {
            return weekDate.formattedWeekRange
        }
    }

    private var availableWeeks: [Date] {
        var weeks: [Date] = []
        let calendar = Calendar.current

        // Generate weeks from 6 months ago to current week (no future weeks)
        let startDate = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let endDate = Date()

        var currentDate = startDate.startOfWeek
        while currentDate <= endDate.startOfWeek {
            weeks.append(currentDate)
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }

        return weeks.reversed() // Most recent first, oldest at bottom
    }
}

// MARK: - Custom Month Picker
struct CustomMonthPicker: View {
    @Binding var selectedMonth: Date

    var body: some View {
        Picker("Select Month", selection: $selectedMonth) {
            ForEach(availableMonths, id: \.self) { monthDate in
                Text(monthDate.formattedMonthYear)
                    .tag(monthDate)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }

    private var availableMonths: [Date] {
        var months: [Date] = []
        let calendar = Calendar.current

        // Generate months from 3 years ago to current month (no future months)
        let startDate = calendar.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        let endDate = Date()

        var currentDate = startDate.startOfMonth
        while currentDate <= endDate.startOfMonth {
            months.append(currentDate)
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }

        return months.reversed() // Most recent first, oldest at bottom
    }
}

// MARK: - Custom Year Picker
struct CustomYearPicker: View {
    @Binding var selectedYear: Date

    var body: some View {
        Picker("Select Year", selection: $selectedYear) {
            ForEach(availableYears, id: \.self) { yearDate in
                Text(yearDate.formattedYear)
                    .tag(yearDate)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }

    private var availableYears: [Date] {
        var years: [Date] = []
        let calendar = Calendar.current

        // Generate years from 5 years ago to current year (no future years)
        let startDate = calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        let endDate = Date()

        var currentDate = startDate.startOfYear
        while currentDate <= endDate.startOfYear {
            years.append(currentDate)
            currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
        }

        return years.reversed() // Most recent first, oldest at bottom
    }
}

// MARK: - Action Button Style
struct ActionButtonStyle: ButtonStyle {
    let textColor: Color
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var selectedTimeFrame: TimeFrame = .currentWeek
    @Previewable @State var selectedWeekDate: Date = Date()
    @Previewable @State var selectedMonthDate: Date = Date()
    @Previewable @State var selectedYearDate: Date = Date()

    VStack(spacing: 20) {
        TimeFramePicker(
            selectedTimeFrame: $selectedTimeFrame,
            selectedWeekDate: $selectedWeekDate,
            selectedMonthDate: $selectedMonthDate,
            selectedYearDate: $selectedYearDate
        )

        Text("Selected: \(selectedTimeFrame.displayName)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
