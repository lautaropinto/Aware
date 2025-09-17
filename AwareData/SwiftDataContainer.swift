//
//  File.swift
//  AwareData
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData

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
                "iCloud.com.aware.db.container.aware-timers"
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
