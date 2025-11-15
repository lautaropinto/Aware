//
//  Storage.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import Foundation
import SwiftData
import Observation
import AwareData
import Combine

@Observable
final class Storage {
    var tags: [Tag] = []
    var timers: [Timekeeper] = []
    
    var timer: Timekeeper?
    
    var Cancellables: Set<AnyCancellable> = .init()
    
    var modelContext: ModelContext! {
        didSet {
            fetchTags()
            fetchActiveTimer()
        }
    }
    
    private func fetchTags() {
        print("Sran dale capo")
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.displayOrder)])
        tags = try! modelContext.fetch(descriptor)
        print("Result: \(tags.count)")
    }
    
    private func fetchActiveTimer() {
        let predicate = #Predicate<Timekeeper> {
            $0.endTime == nil
        }
        
        let descriptor = FetchDescriptor<Timekeeper>(predicate: predicate)
        let timers = try! modelContext.fetch(descriptor)
        self.timer = timers.first
        
        timer.publisher.sink { print("Timer: \($0)") }.store(in: &Cancellables)
    }
    
    func fetchTimers(_ predicate: Predicate<Timekeeper>) {
        let descriptor = FetchDescriptor(predicate: predicate)
        self.timers = try! modelContext.fetch(descriptor)
    }
    
    func getTimers(_ predicate: Predicate<Timekeeper>) -> [Timekeeper] {
        let descriptor = FetchDescriptor(predicate: predicate)
        let timers = try! modelContext.fetch(descriptor)
        
        return timers
    }
    
    func startNewTimer(with tag: Tag) {
        let timer = Timekeeper(name: "\(tag.name) Session", tags: [tag])
        modelContext.insert(timer)
        timer.start()
        try? modelContext.save()
        fetchActiveTimer()
    }
}
