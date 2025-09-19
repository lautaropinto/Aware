//
//  DateExtensions.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import Foundation

extension Date {
    //MARK: Date Properties
    var previousDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self)!
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
}
