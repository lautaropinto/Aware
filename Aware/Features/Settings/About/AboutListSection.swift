//
//  AboutListSection.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

struct AboutListSection: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Section {
            HealthKitButton()
            
            NavigationLink {
                AboutView()
            } label: {
                HStack {
                    Label("About aware", systemImage: "hourglass.bottomhalf.filled")
                        .labelStyle(ColorfulIcon(color: .accent))
                }
            }
            .listRowBackground(Color.gray.opacity(0.1))
            
            Button {
                openURL(URL(string: "https://lautaropinto.com/aware-privacy-policy")!)
            } label: {
                HStack {
                    Label("Privacy policy", systemImage: "lock.shield.fill")
                        .labelStyle(ColorfulIcon(color: .accent))
                    
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .imageScale(.small)
                        .foregroundStyle(Color.secondary)
                }
            }
            .listRowBackground(Color.gray.opacity(0.1))
        }
    }
}

#Preview {
    AboutListSection()
}
