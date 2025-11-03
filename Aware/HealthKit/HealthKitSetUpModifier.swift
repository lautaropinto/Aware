//
//  HealthKitSetUpModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//

import SwiftUI
import HealthKit
import HealthKitUI
import OSLog

private var logger = Logger(subsystem: "HealthKit", category: "SetUpModifier")

private struct HealthKitSetUpModifier: ViewModifier {
    @Binding var toggleHealthDataAuthorization: Bool
    let includeSleepData: Bool
    
    private let healthStore = HealthStore.shared.healthStore

    func body(content: Content) -> some View {
        let readTypes: Set<HKObjectType> = {
            var types: Set<HKObjectType> = []
            if includeSleepData {
                types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
            }
            return types
        }()
        
        content
            .healthDataAccessRequest(store: healthStore,
                                     shareTypes: [.stateOfMindType()],
                                     readTypes: readTypes,
                                     trigger: toggleHealthDataAuthorization) { @Sendable result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        logger.info("HealthKit permissions granted correctly.")
                    case .failure(let error):
                        let errorString = String(describing: error)
                        logger.error("Error when requesting HealthKit read authorizations: \(errorString)")
                    }
                }
            }
    }
}

public extension View {
    func healthKitSetUp(trigger: Binding<Bool>, includeSleepData: Bool = false) -> some View {
        modifier(HealthKitSetUpModifier(toggleHealthDataAuthorization: trigger, includeSleepData: includeSleepData))
    }
}

