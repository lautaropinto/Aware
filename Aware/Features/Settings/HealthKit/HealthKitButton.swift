//
//  HealthKitButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import SwiftUI

struct HealthKitButton: View {
    @Environment(\.openURL) private var openURL
    @AppStorage(.UserDefault.hasGrantedSleepReadPermission) var hasSleepPermission: Bool = false
    @State private var healthKitTrigger = false

    var body: some View {
        Button {
            guard !self.hasSleepPermission else { return }
            
            if self.hasSleepPermission {
                let settingsURL = URL(string: UIApplication.openSettingsURLString)!
                openURL(settingsURL)
            } else {
                healthKitTrigger.toggle()
            }
        } label: {
            HStack {
                Label("Health Kit", systemImage: "heart.fill")
                    .labelStyle(ColorfulIcon(color: .accent))
                
                Spacer()
                
                if self.hasSleepPermission {
                    Text("Connected")
                        .foregroundStyle(.green)
                } else {
                    Text("Not Connected")
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.up.right")
                        .imageScale(.small)
                        .foregroundStyle(Color.secondary)
                }
            }
            .listRowBackground(Color.gray.opacity(0.1))
        }
        .listRowBackground(Color.gray.opacity(0.1))
        .healthKitSetUp(trigger: $healthKitTrigger)
    }
}

#Preview {
    List {
        HealthKitButton()
    }
}
