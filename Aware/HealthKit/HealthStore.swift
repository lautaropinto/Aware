//
//  HealthStore.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//

import HealthKit

/// A reference to the shared `HKHealthStore` for views to use.
final class HealthStore: Sendable {
    
    static let shared: HealthStore = HealthStore()
    
    let healthStore = HKHealthStore()
    
    private init() { }
}
