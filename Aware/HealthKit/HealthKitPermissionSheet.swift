//
//  HealthKitPermissionSheet.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/3/25.
//

import SwiftUI
import HealthKit

struct HealthKitPermissionSheet: View {
    @Binding var isPresented: Bool
    let onSetupNow: () -> Void
    let onSetupLater: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                HStack(spacing: 24.0) {
                    Image("healthKit")
                        .resizable()
                        .frame(width: 80.0, height: 80.0)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18.0)
                                .stroke(.secondary.opacity(0.36), lineWidth: 1.0)
                        }
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary.opacity(0.86))
                    
                    Image("aware")
                        .resizable()
                        .frame(width: 80.0, height: 80.0)
                }

                // Title
                Text("Connect to Apple Health")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Description
                VStack(spacing: 16) {
                    Text("Aware now connects with Apple Health to bring more context to your time.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)

                    Text("*Your data stays private and on your device, it’s only used to create a more meaningful view of your days and insights.")
                        .font(.caption)
                        .italic()
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Buttons
                VStack(spacing: 24) {
                    Button("Maybe Later") {
                        onSetupLater()
                    }
                    .controlSize(.large)
                    .bold()
                    
                    Button("Connect") {
                        onSetupNow()
                    }
                    .buttonStyle(DefaultBigButton(color: .accentColor))
                    .controlSize(.large)
                    .glassEffect(.regular.interactive())
                }
                .padding(.horizontal, 20)
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        onSetupLater()
                    }
                }
            }
        }
    }
}

#Preview {
    HealthKitPermissionSheet(
        isPresented: .constant(true),
        onSetupNow: {},
        onSetupLater: {}
    )
}
