//
//  EmptyState.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI

struct EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No activities yet",
            systemImage: "apps.iphone.badge.plus",
            description:
                Text("Timers in Aware are always tied to an acitivy. Add your first activity in the iPhone app to start intentional timers here on Apple watch.")
        )
    }
}

#Preview {
    EmptyState()
}
