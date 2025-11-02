//
//  SettingsButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

struct SettingsButton: View {
    @Binding private var isSettingsPresented: Bool
    
    private let transition: Namespace.ID
    
    init(isSettingsPresented: Binding<Bool>, transition: Namespace.ID) {
        self.transition = transition
        self._isSettingsPresented = isSettingsPresented
    }
    
    var body: some View {
        Button {
            isSettingsPresented = true
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.primary)
        }
    }
}
