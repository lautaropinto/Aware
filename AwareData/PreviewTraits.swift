//
//  File.swift
//  AwareData
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData

private struct SwiftDataPreviewTrait: PreviewModifier {
    var emptyModels: Bool = false
    var tags: [Tag] = []
    var timers: [Timekeeper] = []
    
    @Environment(\.modelContext) private var modelContext
    
    func body(content: Content, context: ModelContainer) -> some View {
        return content
            .modelContainer(context)
            .onAppear {
                addMocks(to: context)
            }
    }
    
    static func makeSharedContext() async throws -> ModelContainer {
        let modifier = AwareDataContainerViewModifier(inMemory: true)
        
        return modifier.container
    }
    
    func addMocks(to modelContainer: ModelContainer) {
        if !tags.isEmpty {
            tags.forEach { modelContainer.mainContext.insert($0) }
        }
        
        if !timers.isEmpty {
            timers.forEach { modelContainer.mainContext.insert($0) }
        }
    }
}

public extension PreviewTrait where T == Preview.ViewTraits {
    static let emptySwiftData: Self = swiftData()
    
    static func swiftData(emptyModels: Bool = false,
                          tags: [Tag] = [],
                          timers: [Timekeeper] = []) -> Self {
        .modifier(
            SwiftDataPreviewTrait(
                emptyModels: emptyModels,
                tags: tags,
                timers: timers
            )
        )
    }
    
    static let defaultTagsSwiftData: Self = swiftData(tags: Tag.defaultTags)
}
