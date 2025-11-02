//
//  CircledSmallButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//

import SwiftUI

struct CircledSmallButton: ButtonStyle {
    let color: Color

    @Environment(\.isEnabled) private var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.background)
            .frame(width: 30.0, height: 30.0)
            .background(Circle().foregroundStyle(isEnabled ? color : .secondary.opacity(0.36)))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
