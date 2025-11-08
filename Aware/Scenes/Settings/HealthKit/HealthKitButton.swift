//
//  HealthKitButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import SwiftUI

struct HealthKitButton: View {
    @State private var showHealthKitPermissionSheet = false
    @State private var healthKitTrigger = false
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button {
            if HealthStore.shared.hasSleepPermissions() {
                let settingsURL = URL(string: UIApplication.openSettingsURLString)!
                openURL(settingsURL)
            } else {
                showHealthKitPermissionSheet = true
            }
        } label: {
            HStack {
                Label("Health Kit", systemImage: "heart.fill")
                    .labelStyle(ColorfulIcon(color: .accent))
                
                Spacer()
                
                if HealthStore.shared.hasSleepPermissions() {
                    Text("Connected")
                        .foregroundStyle(.green)
                } else {
                    Text("Not Connected")
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "arrow.up.right")
                    .imageScale(.small)
                    .foregroundStyle(Color.secondary)
            }
            .listRowBackground(Color.gray.opacity(0.1))
        }
        .listRowBackground(Color.gray.opacity(0.1))
        .healthKitSetUp(trigger: $healthKitTrigger)
        .sheet(isPresented: $showHealthKitPermissionSheet) {
            HealthKitPermissionSheet(
                isPresented: $showHealthKitPermissionSheet,
                onSetupNow: {
                    healthKitTrigger.toggle()
                    showHealthKitPermissionSheet = false
                },
                onSetupLater: {
                    showHealthKitPermissionSheet = false
                }
            )
        }
    }
}

#Preview {
    List {
        HealthKitButton()
    }
}
