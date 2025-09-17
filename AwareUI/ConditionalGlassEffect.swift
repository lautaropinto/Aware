//
//  SwiftUIView.swift
//  AwareUI
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI

private struct ConditionalGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect()
        } else {
            content
        }
    }
}

public extension View {
    func glassEffectIfAvailable() -> some View {
        modifier(ConditionalGlassEffect())
    }
}
