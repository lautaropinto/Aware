//
//  BackgroundGradient.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI

extension Color {
    static var background: Color {
        Color(.systemBackground)
    }
}


private struct BackgroundModifier: ViewModifier {
    @Environment(\.appConfig) var config

    private func palette() -> (main: Color, secondary: Color, tertiary: Color) {
        let base = config.backgroundColor
        let background = Color.background
        let main = base.mix(with: background, by: 0.6)
        let secondary = base.mix(with: background, by: 0.7)
        let tertiary = base.mix(with: background, by: 0.9)
        return (main, secondary, tertiary)
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [palette().main, palette().secondary, palette().tertiary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .colorEffect(ShaderLibrary.parameterizedNoise(.float(0.5), .float(1.0), .float(0.2)))
                .edgesIgnoringSafeArea(.all)
            )
            .scrollContentBackground(.hidden)
    }
}


public extension View {
    func applyBackgroundGradient() -> some View {
        modifier(BackgroundModifier())
    }
}

#Preview {
    VStack {
        HStack {
            Spacer()
        }
        Text("Sran")
        Spacer()
    }
        .ignoresSafeArea(.all)
        .applyBackgroundGradient()
}


extension Array {
    /// Returns a new array with randomly sampled elements from the original array
    /// - Parameter count: The number of elements to sample (defaults to the array length)
    /// - Returns: A new array with randomly sampled elements
    func randomSample(count: Int? = nil) -> [Element] {
        let sampleCount = count ?? self.count
        guard sampleCount > 0, !isEmpty else { return [] }

        // If requesting more elements than available, repeat elements
        if sampleCount > self.count {
            var result: [Element] = []
            while result.count < sampleCount {
                result.append(contentsOf: self.shuffled())
            }
            return Array(result.prefix(sampleCount))
        }

        return Array(shuffled().prefix(sampleCount))
    }
}
