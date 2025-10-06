//
//  SettingsButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

struct SettingsButton: View {
    @State private var isSettingsPresented = false
    
    private let transition: Namespace.ID
    
    init(transition: Namespace.ID) {
        self.transition = transition
    }
    
    var body: some View {
        Button {
            isSettingsPresented = true
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.primary)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsScene()
                .navigationTransition(.zoom(sourceID: "settings", in: transition))
        }
    }
}
