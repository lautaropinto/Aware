//
//  TimelineEntry.swift
//  AwareData
//
//  Created by Lautaro Pinto on 11/2/25.
//

import Foundation
import SwiftUI

public enum TimelineEntryType {
    case timekeeper
    case sleep
    case workout
}

public protocol TimelineEntry: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var creationDate: Date { get }
    var startTime: Date? { get }
    var endTime: Date? { get }
    var duration: TimeInterval { get }
    var swiftUIColor: Color { get } // Hex color
    var image: String { get }
    var type: TimelineEntryType { get }
}
