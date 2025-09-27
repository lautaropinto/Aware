//
//  File.swift
//  AwareData
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData

public extension ModelContainer {
    static var defaultConfig: ModelContainer? {
        let schema = SwiftData.Schema([
            Tag.self,
            Timekeeper.self,
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(
                "iCloud.aware-timers"
            )
        )
        
        return try? ModelContainer(
            for: schema,
            configurations: config
        )
    }
}

struct AwareDataContainerViewModifier: ViewModifier {
    let container: ModelContainer
    
    let schema = SwiftData.Schema([
        Tag.self,
        Timekeeper.self,
    ])
    
    
    init(inMemory: Bool) {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .private(
                "iCloud.aware-timers"
            )
        )
        container = try! ModelContainer(
            for: schema,
            configurations: config
        )
    }
    
    func body(content: Content) -> some View {
        content
            .modelContainer(container)
    }
}

public extension View {
    func swiftDataSetUp(inMemory: Bool = false) -> some View {
        modifier(AwareDataContainerViewModifier(inMemory: inMemory))
    }
}
