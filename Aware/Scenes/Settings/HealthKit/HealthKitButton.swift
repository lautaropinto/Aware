//
//  HealthKitButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import SwiftUI

struct HealthKitButton: View {
    @State private var showHealthKitPermissionSheet = false
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button {
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            openURL(settingsURL)
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
        .sheet(isPresented: $showHealthKitPermissionSheet) {
            HealthKitPermissionSheet(
                isPresented: $showHealthKitPermissionSheet,
                onSetupNow: {
                    showHealthKitPermissionSheet = false
                    Task {
                        await HealthStore.shared.requestSleepPermissions()
                    }
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
