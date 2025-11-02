//
//  CircledSmallButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/2/25.
//

import SwiftUI

struct CircledSmallButton: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.background)
            .frame(width: 30.0, height: 30.0)
            .background(Circle().foregroundStyle(color))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
