//
//  BackgroundGradient.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI

public extension View {
    func applyBackgroundGradient() -> some View {
        modifier(BackgroundModifier())
    }
}

private struct BackgroundModifier: ViewModifier {
    @Environment(\.appConfig) var config
    
    func body(content: Content) -> some View {
        content
            .background(BackgroundMeshGradient(color: config.backgroundColor))
    }
}

private struct BackgroundMeshGradient: View {
    var color: Color
    
    @State private var points: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]
    
    @State private var shouldAnimate = false
    @State private var colors: [Color]
    
    init(color: Color) {
        self.color = color
        let palette = BackgroundMeshGradient.palette(for: color)
        _colors = State(initialValue: [
            palette.secondary, palette.main, palette.secondary,
            palette.secondary, palette.secondary, palette.tertiary,
            palette.tertiary, palette.main, palette.tertiary,
        ])
    }
        
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: points,
            colors: colors
        )
        #if !os(watchOS)
        .colorEffect(ShaderLibrary.parameterizedNoise(.float(0.5), .float(1.0), .float(0.2)))
        #endif
        .ignoresSafeArea()
        .onAppear {
            shouldAnimate = true
            shuffleColors()
        }
        .onDisappear {
            print("Mesh gradient on disappear")
            shouldAnimate = false
        }
        .onChange(of: color) { _, newColor in
            let palette = BackgroundMeshGradient.palette(for: newColor)
            let newColors: [Color] = [
                palette.secondary, palette.main, palette.secondary,
                palette.secondary, palette.secondary, palette.tertiary,
                palette.tertiary, palette.main, palette.tertiary,
            ]
            withAnimation(.easeInOut(duration: 0.6)) {
                colors = newColors
            }
            shuffleColors()
        }
    }
    
    func shuffleColors() {
        guard shouldAnimate else { return }
        
        withAnimation(.easeInOut(duration: 10.0)) {
            colors = colors.randomSample(count: colors.count)
        } completion: {
            shuffleColors()
        }
    }
    
    private static func palette(for base: Color) -> (main: Color, secondary: Color, tertiary: Color) {
        let main = base.mix(with: .black, by: 0.6)
        let secondary = base.mix(with: .black, by: 0.7)
        let tertiary = base.mix(with: .black, by: 0.9)
        return (main, secondary, tertiary)
    }
}

struct BackgroundGradient: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
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
