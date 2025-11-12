//
//  RoundedModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/12/25.
//

import SwiftUI

private struct RoundedModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
    }
}

extension View {
    func rounded() -> some View {
        modifier(RoundedModifier())
    }
}
