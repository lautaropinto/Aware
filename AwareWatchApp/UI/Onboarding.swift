//
//  Onboarding.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI

struct Onboarding: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Timers, made simple")
                    .font(.headline)
                
                Text("On Apple Watch, Aware is all about the essentials - start, pause, and stop your timers.\nCreate and manage activities from the iPhone app.")
                
                Button("Got it") {
                    dismiss()
                }
                .tint(.teal)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}

#Preview {
    Onboarding()
}
