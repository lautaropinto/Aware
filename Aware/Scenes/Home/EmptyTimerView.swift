//
//  EmptyTimerView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI

struct EmptyTimerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Empty space where timer name would be
            Spacer()
                .frame(height: 44) // Approximate height of title + tag
            
            // Time Display (00:00)
            Text("00:00")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
            
            // Empty space where buttons would be
            Spacer()
                .frame(height: 44) // Approximate height of button row
            
            // Disclaimer text
            Text("Start tracking your time with a quick timer below")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(1.0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(24)
    }
}
