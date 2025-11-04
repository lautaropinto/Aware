//
//  String+UserDefaultKeys.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/3/25.
//

import Foundation

extension String {
    struct UserDefault {
        static let showUntrackedTime = "aware-insights-showUntrackedTime"
        static let selectedTimeFrame = "aware-insights-selectedTimeFrame"
        static let healthKitSleepPermissionsRequested = "aware-healthkit-sleep-permissions-requested"
        static let healthKitSleepPermissionsGranted = "aware-healthkit-sleep-permissions-granted"
    }
}
