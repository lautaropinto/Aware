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

public enum GradientDirection {
    case toBottom, toTop
    
    var startPoint: UnitPoint {
        self == .toBottom ? .top : .bottom
    }
    
    var endPoint: UnitPoint {
        self == .toBottom ? .bottom : .top
    }
}

private struct BackgroundModifier: ViewModifier {
    @Environment(\.appConfig) private var config
    @Environment(\.colorScheme) private var scheme
    
    let direction: GradientDirection

    private func palette() -> (main: Color, secondary: Color, tertiary: Color) {
        let base = config.backgroundColor
        let background = Color.background
        let main = base.mix(with: background, by: 0.7)
        let secondary = base.mix(with: background, by: 0.8)
        let tertiary = base.mix(with: background, by: 0.9)
        return (main, secondary, tertiary)
    }
    
    func body(content: Content) -> some View {
        if scheme == .dark {
            content
                .background(
                    LinearGradient(
                        colors: [palette().main, palette().secondary, palette().tertiary],
                        startPoint: direction.startPoint,
                        endPoint: direction.endPoint
                    )
                    .colorEffect(ShaderLibrary.parameterizedNoise(.float(0.5), .float(1.0), .float(0.2)))
                    .edgesIgnoringSafeArea(.all)
                )
                .scrollContentBackground(.hidden)
        } else {
            content
                .background(
                    LinearGradient(
                        colors: [palette().main, palette().secondary, palette().tertiary],
                        startPoint: direction.startPoint,
                        endPoint: direction.endPoint
                    )
                    .edgesIgnoringSafeArea(.all)
                )
                .scrollContentBackground(.hidden)
        }
    }
}

public extension View {
    func applyBackgroundGradient(_ direction: GradientDirection = .toTop) -> some View {
        modifier(BackgroundModifier(direction: direction))
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
