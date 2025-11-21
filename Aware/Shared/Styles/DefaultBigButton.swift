//
//  DefaultBigButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//

import SwiftUI

struct DefaultBigButton: ButtonStyle {
    let color: Color

    @Environment(\.isEnabled) private var isEnabled: Bool
    
    init(color: Color = .clear) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let opacity = configuration.isPressed || !isEnabled ? 0.75 : 1.0
        
        configuration.label
            .font(.headline)
            .foregroundColor(isEnabled ? Color.white : Color.gray)
            .frame(maxWidth: .infinity)
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(opacity)
            .glassEffect(
                .regular
                    .interactive(isEnabled)
                    .tint(isEnabled ? color : Color.gray),
                in: .containerRelative
            )
            .clipShape(Capsule())
            .contentShape(.capsule)
    }
}

extension ButtonStyle where Self == DefaultBigButton {
    static var defaultCapsule: Self { .init() }
}
