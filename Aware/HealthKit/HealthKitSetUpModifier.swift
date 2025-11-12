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
    
    private let healthStore = HealthStore.shared.healthStore

    func body(content: Content) -> some View {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
        ]
        
        content
            .healthDataAccessRequest(
                store: healthStore,
                shareTypes: [],
                readTypes: readTypes,
                trigger: toggleHealthDataAuthorization
            ) { result in
                switch result {
                case .success:
                    logger.info("HealthKit permissions granted correctly.")
                    UserDefaults.standard.setBool(true, for: .UserDefault.hasGrantedSleepReadPermission)
                    UserDefaults.standard.setBool(true, for: .UserDefault.hasGrantedWorkoutReadPermission)
                case .failure(let error):
                    let errorString = String(describing: error)
                    logger.error("Error when requesting HealthKit read authorizations: \(errorString)")
                }
            }
    }
}

public extension View {
    func healthKitSetUp(trigger: Binding<Bool>) -> some View {
        modifier(HealthKitSetUpModifier(toggleHealthDataAuthorization: trigger))
    }
}
