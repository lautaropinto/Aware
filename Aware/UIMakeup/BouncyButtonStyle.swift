//
//  DefaultBigButton 2.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/16/25.
//

import SwiftUI

struct Bouncy: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.22 : 1.0)
    }
}

extension ButtonStyle where Self == Bouncy {
    static var bouncy: Self { .init() }
}
