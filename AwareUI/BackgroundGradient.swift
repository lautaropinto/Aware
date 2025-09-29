//
//  BackgroundGradient.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI

@MainActor
@Observable
private class GradientEngine: @MainActor GradientEngineProtocol {
    private(set) var meshPoints: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]

    private(set) var meshColors: [Color] = []
    private(set) var isAnimating = false

    private var animationTask: Task<Void, Never>?
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

    func startAnimationIfNeeded() {
        guard !isAnimating else { return }
        isAnimating = true

        animationTask = Task {
            await startContinuousAnimation()
        }
    }

    func stopAnimation() {
        isAnimating = false
        animationTask?.cancel()
        animationTask = nil
    }

    func pauseAnimation() {
        // Pause animation but keep state
        animationTask?.cancel()
        animationTask = nil
        // Don't set isAnimating to false - we want to resume where we left off
    }

    func resumeAnimation() {
        guard isAnimating else { return }
        // Resume animation if it was running
        animationTask = Task {
            await startContinuousAnimation()
        }
    }

    private func startContinuousAnimation() async {
        while isAnimating && !Task.isCancelled {
            await shuffleColors()

            // Wait for 10 seconds before next shuffle
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                // Task was cancelled, exit gracefully
                break
            }
        }
    }

    private func shuffleColors() async {
        guard isAnimating && !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 10.0)) {
            meshColors = meshColors.randomSample(count: meshColors.count)
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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let engine = engine {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: engine.meshPoints,
                    colors: engine.meshColors
                )
                #if !os(watchOS)
                .colorEffect(ShaderLibrary.parameterizedNoise(.float(0.5), .float(1.0), .float(0.2)))
                #endif
                .ignoresSafeArea()
                .onChange(of: config.backgroundColor) { _, newColor in
                    Task { @MainActor in
                        engine.updateBaseColor(newColor)
                    }
                }
            } else {
                // Fallback while engine is being set up
                Rectangle()
                    .fill(config.backgroundColor.mix(with: .black, by: 0.7))
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            Task { @MainActor in
                setupEngine()
            }
        }
        .onDisappear {
            // Don't stop the engine - let it continue for other views
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task { @MainActor in
                handleScenePhaseChange(newPhase)
            }
        }
    }

    @MainActor
    private func setupEngine() {
        if config.gradientEngine == nil {
            let newEngine = GradientEngine()
            config.setGradientEngine(newEngine)
        }

        if let sharedEngine = config.gradientEngine as? GradientEngine {
            engine = sharedEngine
            sharedEngine.startAnimationIfNeeded()
        }
    }

    @MainActor
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard let engine = config.gradientEngine else { return }

        switch phase {
        case .active:
            engine.resumeAnimation()
        case .inactive, .background:
            engine.pauseAnimation()
        @unknown default:
            break
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
