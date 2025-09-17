//
//  TimerList.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData
import AwareData
import AwareUI

struct TimerList: View {
    @Binding var currentTimer: Timekeeper?
    
    @Query(sort: \AwareData.Tag.displayOrder) private var tags: [AwareData.Tag]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appConfig) private var appConfig
    
    var body: some View {
        if tags.isEmpty {
            EmptyState()
        } else {
            List {
                Section("Start a timer") {
                    ForEach(tags) { tag in
                        ListRow(tag: tag)
                            .onTapGesture {
                                createAndStartTimer(with: tag)
                            }
                    }
                }
            }
        }
    }
    
    private func createAndStartTimer(with tag: Tag) {
        let timer = Timekeeper(name: "\(tag.name) Session", tag: tag)
        modelContext.insert(timer)
        timer.start()
        currentTimer = timer
        try? modelContext.save()
        withAnimation {
            appConfig.backgroundColor = timer.tag?.swiftUIColor ?? .teal
        }
    }
}
