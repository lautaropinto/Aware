//
//  InsightsEmptyState.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/3/25.
//

import SwiftUI

struct InsightsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Data Available")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("Start tracking your time to see insights")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)

    }
}
