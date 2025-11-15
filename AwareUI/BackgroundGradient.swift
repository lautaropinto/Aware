//
//  BackgroundGradient.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI

@Observable
private class GradientEngine: @MainActor GradientEngineProtocol {
    private(set) var meshPoints: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]

    private(set) var meshColors: [Color] = []
    private var currentBaseColor: Color = .accentColor

    init() {
        updateColors(for: currentBaseColor)
    }

    func updateBaseColor(_ color: Color) {
        guard color != currentBaseColor else { return }
        currentBaseColor = color

        let palette = Self.palette(for: color)
        let newColors: [Color] = [
            palette.secondary, palette.main, palette.secondary,
            palette.secondary, palette.secondary, palette.tertiary,
            palette.tertiary, palette.main, palette.tertiary,
        ]

        withAnimation(.easeInOut(duration: 0.6)) {
            meshColors = newColors
        }
    }

    private func updateColors(for baseColor: Color) {
        let palette = Self.palette(for: baseColor)
        meshColors = [
            palette.secondary, palette.main, palette.secondary,
            palette.secondary, palette.secondary, palette.tertiary,
            palette.tertiary, palette.main, palette.tertiary,
        ]
    }

    private static func palette(for base: Color) -> (main: Color, secondary: Color, tertiary: Color) {
        let main = base.mix(with: .black, by: 0.6)
        let secondary = base.mix(with: .black, by: 0.7)
        let tertiary = base.mix(with: .black, by: 0.9)
        return (main, secondary, tertiary)
    }

}

public extension View {
    func applyBackgroundGradient() -> some View {
        modifier(BackgroundModifier())
    }
}

private struct BackgroundModifier: ViewModifier {
    @Environment(\.appConfig) var config

    func body(content: Content) -> some View {
        content
            .background(SharedBackgroundMeshGradient(config: config))
    }
}

private struct SharedBackgroundMeshGradient: View {
    let config: CrossConfig

    @State private var engine: GradientEngine?

    var body: some View {
        Group {
            if let engine = engine {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: engine.meshPoints,
                    colors: engine.meshColors
                )
                .colorEffect(ShaderLibrary.parameterizedNoise(.float(0.5), .float(1.0), .float(0.2)))
                .ignoresSafeArea()
                .onChange(of: config.backgroundColor) { _, newColor in
                    Task { @MainActor in
                        engine.updateBaseColor(newColor)
                    }
                }
            } else {
                Rectangle()
                    .fill(config.backgroundColor.mix(with: .black, by: 0.7))
                    .ignoresSafeArea()
            }
        }
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
