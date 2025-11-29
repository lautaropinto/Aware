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
import TelemetryDeck

@main
struct AwareApp: App {
    @Environment(\.modelContext) var modelContext
    @State private var appConfig = CrossConfig(backgroundColor: Color.accent)
    
    init() {
        let config = TelemetryDeck.Config(appID: "48BBE375-B33D-4AC3-8810-5711A8416F55")
        TelemetryDeck.initialize(config: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .swiftDataSetUp()
                .environment(\.appConfig, appConfig)
        }
    }
}
