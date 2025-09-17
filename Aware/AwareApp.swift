//
//  AwareApp.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI

@main
struct AwareApp: App {
    @State private var appConfig = CrossConfig(backgroundColor: Color.accent)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .swiftDataSetUp()
                .environment(\.appConfig, appConfig)
        }
    }
}
