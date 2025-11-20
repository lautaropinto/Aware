//
//  WatchTitle.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/15/25.
//

import SwiftUI
import AwareData

struct WatchTitle: View {
    @Environment(Storage.self) private var storage
    
    @Environment(AwarenessSession.self) private var awarenessSession

    private var timer: Timekeeper? { awarenessSession.activeTimer }
    
    var body: some View {
        VStack(spacing: 8) {
            if let timer = timer {
                Text(timer.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Spacer()
                    .frame(height: 44)
            }
        }
    }
}
