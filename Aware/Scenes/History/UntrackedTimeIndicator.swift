//
//  UntrackedTimeIndicator.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/8/25.
//

import SwiftUI

struct UntrackedTimeIndicator: View {
    let duration: TimeInterval

    private var formattedDuration: String {
        duration.formattedElapsedTime
    }
    
    var body: some View {
        HStack() {
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 1)

                Text(formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()

                Text("untracked")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .italic()
            
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack {
        UntrackedTimeIndicator(duration: 1800) // 30 minutes
        UntrackedTimeIndicator(duration: 3600) // 1 hour
        UntrackedTimeIndicator(duration: 600)  // 10 minutes
    }
    .padding()
}
