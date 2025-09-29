//
//  DateExtensions.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import Foundation

enum TimeFrame: Equatable, Identifiable {
    case week(Date)
    case month(Date)
    case year(Date)
    case allTime

    var id: String {
        switch self {
        case .week(let date):
            return "week-\(date.timeIntervalSince1970)"
        case .month(let date):
            return "month-\(date.timeIntervalSince1970)"
        case .year(let date):
            return "year-\(date.timeIntervalSince1970)"
        case .allTime:
            return "allTime"
        }
    }

    var displayName: String {
        switch self {
        case .week(let date):
            return date.formattedWeekRange
        case .month(let date):
            return date.formattedMonthYear
        case .year(let date):
            return date.formattedYear
        case .allTime:
            return "All Time"
        }
    }

    // Static helpers for current timeframes
    static var currentWeek: TimeFrame {
        .week(Date().startOfWeek)
    }

    static var currentMonth: TimeFrame {
        .month(Date().startOfMonth)
    }

    static var currentYear: TimeFrame {
        .year(Date().startOfYear)
    }

    static var allCases: [TimeFrame] {
        [.currentWeek, .currentMonth, .currentYear, .allTime]
    }

    // Navigation helpers
    func previous() -> TimeFrame? {
        switch self {
        case .week(let date):
            return .week(date.previousWeek())
        case .month(let date):
            return .month(date.previousMonth())
        case .year(let date):
            return .year(date.previousYear())
        case .allTime:
            return nil
        }
    }

    func next() -> TimeFrame? {
        switch self {
        case .week(let date):
            let nextWeek = date.nextWeek()
            // Don't allow future weeks
            guard nextWeek.startOfWeek <= Date().startOfWeek else { return nil }
            return .week(nextWeek)
        case .month(let date):
            let nextMonth = date.nextMonth()
            // Don't allow future months
            guard nextMonth.startOfMonth <= Date().startOfMonth else { return nil }
            return .month(nextMonth)
        case .year(let date):
            let nextYear = date.nextYear()
            // Don't allow future years
            guard nextYear.startOfYear <= Date().startOfYear else { return nil }
            return .year(nextYear)
        case .allTime:
            return nil
        }
    }

    var canNavigatePrevious: Bool {
        previous() != nil
    }

    var canNavigateNext: Bool {
        next() != nil
    }

    // Date range for filtering
    var dateRange: (start: Date, end: Date)? {
        switch self {
        case .week(let date):
            return (start: date.startOfWeek, end: date.endOfWeek)
        case .month(let date):
            return (start: date.startOfMonth, end: date.endOfMonth)
        case .year(let date):
            return (start: date.startOfYear, end: date.endOfYear)
        case .allTime:
            return nil
        }
    }
}

extension Date {
    //MARK: Date Properties
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var previousDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }

    var nextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .second, value: -1, to: self.nextDay.startOfDay)!
    }

    // MARK: - Week utilities
    var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }

    var endOfWeek: Date {
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)?.endOfDay ?? self
    }

    func previousWeek() -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: self) ?? self
    }

    func nextWeek() -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: self) ?? self
    }

    // MARK: - Month utilities
    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth
        return calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.previousDay.endOfDay ?? self
    }

    func previousMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: self) ?? self
    }

    func nextMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: 1, to: self) ?? self
    }

    // MARK: - Year utilities
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfYear: Date {
        let calendar = Calendar.current
        let startOfYear = self.startOfYear
        return calendar.date(byAdding: .year, value: 1, to: startOfYear)?.previousDay.endOfDay ?? self
    }

    func previousYear() -> Date {
        return Calendar.current.date(byAdding: .year, value: -1, to: self) ?? self
    }

    func nextYear() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: self) ?? self
    }
    
    /// Will return formatted hours and minutes.
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: self)
    }
    
    /// Will return formatted date: Friday, 19 sep
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: self)
    }
    
    /// Will return Yesterday / Today smartly. Otherwise the format is: Friday, 19 sep
    var smartFormattedDate: String {
        guard !self.isInSameDay(as: Date.now) else {
            return "Today"
        }
        
        guard !self.isInSameDay(as: Date.now.previousDay) else {
            return "Yesterday"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: self)
    }
    
    //MARK: - Date Functions
    
    func isInSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        
        return calendar.isDate(self, inSameDayAs: date)
    }

    // MARK: - Formatting for TimeFrame navigation
    var formattedWeekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startWeek = self.startOfWeek
        let endWeek = self.endOfWeek

        let startString = formatter.string(from: startWeek)
        let endString = formatter.string(from: endWeek)

        return "\(startString) - \(endString)"
    }

    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var formattedYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
}
