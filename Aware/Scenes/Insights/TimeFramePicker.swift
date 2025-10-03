//
//  TimeFramePicker.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/29/25.
//

import SwiftUI

struct TimeFramePicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    @Binding var selectedDayDate: Date
    @Binding var selectedWeekDate: Date
    @Binding var selectedMonthDate: Date
    @Binding var selectedYearDate: Date
    @Binding var showUntrackedTime: Bool
    let availableTimeFrames: [TimeFrame]

    @State private var showingPeriodSelector = false
    @State private var hasAppeared = false
    @State private var hasEverAppeared = false

    init(
        selectedTimeFrame: Binding<TimeFrame>,
        selectedDayDate: Binding<Date>,
        selectedWeekDate: Binding<Date>,
        selectedMonthDate: Binding<Date>,
        selectedYearDate: Binding<Date>,
        showUntrackedTime: Binding<Bool> = .constant(false),
        availableTimeFrames: [TimeFrame] = TimeFrame.allCases
    ) {
        self._selectedTimeFrame = selectedTimeFrame
        self._selectedDayDate = selectedDayDate
        self._selectedWeekDate = selectedWeekDate
        self._selectedMonthDate = selectedMonthDate
        self._selectedYearDate = selectedYearDate
        self._showUntrackedTime = showUntrackedTime
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
            HStack {
                DateNavigationView()
                
                if case .daily = selectedTimeFrame {
                    UntrackedTimeToggle()
                } else {
                    UntrackedTimeToggle()
                        .opacity(0)
                }
            }
            .opacity(hasAppeared && selectedTimeFrame != .allTime ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
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
                case "daily":
                    UserDefaults.standard.set(0, forKey: .UserDefault.selectedTimeFrame)
                    selectedTimeFrame = .daily(selectedDayDate)
                case "week":
                    UserDefaults.standard.set(1, forKey: .UserDefault.selectedTimeFrame)
                    selectedTimeFrame = .week(selectedWeekDate)
                case "month":
                    UserDefaults.standard.set(2, forKey: .UserDefault.selectedTimeFrame)
                    selectedTimeFrame = .month(selectedMonthDate)
                case "year":
                    UserDefaults.standard.set(3, forKey: .UserDefault.selectedTimeFrame)
                    selectedTimeFrame = .year(selectedYearDate)
                case "allTime":
                    UserDefaults.standard.set(4, forKey: .UserDefault.selectedTimeFrame)
                    selectedTimeFrame = .allTime
                default:
                    break
                }
            }
        )) {
            Text("Day").tag("daily")
            Text("Week").tag("week")
            Text("Month").tag("month")
            Text("Year").tag("year")
            Text("All Time").tag("allTime")
        }
        .pickerStyle(.segmented)
    }

    private var timeFrameType: String {
        switch selectedTimeFrame {
        case .daily:
            return "daily"
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
        case .daily(let date):
            selectedDayDate = date
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
                case .daily:
                    DayDatePicker()
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
        case .daily:
            return "Select day"
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
    private func DayDatePicker() -> some View {
        CustomDayPicker(
            selectedDay: Binding(
                get: { currentDayDate },
                set: { newDate in
                    selectedDayDate = newDate
                    selectedTimeFrame = .daily(newDate)
                }
            )
        )
    }

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

    private var currentDayDate: Date {
        switch selectedTimeFrame {
        case .daily(let date):
            return date
        default:
            return selectedDayDate
        }
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
    @Previewable @State var selectedDayDate: Date = Date()
    @Previewable @State var selectedWeekDate: Date = Date()
    @Previewable @State var selectedMonthDate: Date = Date()
    @Previewable @State var selectedYearDate: Date = Date()
    @Previewable @State var showUntrackedTime: Bool = false

    VStack(spacing: 20) {
        TimeFramePicker(
            selectedTimeFrame: $selectedTimeFrame,
            selectedDayDate: $selectedDayDate,
            selectedWeekDate: $selectedWeekDate,
            selectedMonthDate: $selectedMonthDate,
            selectedYearDate: $selectedYearDate,
            showUntrackedTime: $showUntrackedTime
        )

        Text("Selected: \(selectedTimeFrame.displayName)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
