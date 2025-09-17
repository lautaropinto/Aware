//
//  DefaultBigButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//

import SwiftUI

struct DefaultBigButton: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        let opacity = configuration.isPressed || !isEnabled ? 0.75 : 1.0
        
        configuration.label
            .font(.headline)
            .foregroundColor(isEnabled ? Color.white : Color.gray)
            .frame(maxWidth: .infinity)
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(opacity)
            .glassEffect(.clear)
            .clipShape(Capsule())
            .contentShape(.capsule)
    }
}

extension ButtonStyle where Self == DefaultBigButton {
    static var defaultCapsule: Self { .init() }
}
