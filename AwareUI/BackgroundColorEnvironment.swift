// BackgroundColorEnvironment.swift
import SwiftUI
import Observation

@Observable
public class CrossConfig {
    public var backgroundColor = Color.accentColor

    // Internal gradient engine - will be initialized by BackgroundGradient
    internal var gradientEngine: GradientEngineProtocol?

    public init(backgroundColor: SwiftUICore.Color = Color.accentColor) {
        self.backgroundColor = backgroundColor
    }

    internal func setGradientEngine(_ engine: GradientEngineProtocol) {
        self.gradientEngine = engine
        engine.updateBaseColor(backgroundColor)
    }
}

// Protocol to avoid circular dependencies
internal protocol GradientEngineProtocol {
    func updateBaseColor(_ color: Color)
    func startAnimationIfNeeded()
    func stopAnimation()
    func pauseAnimation()
    func resumeAnimation()

    var meshPoints: [SIMD2<Float>] { get }
    var meshColors: [Color] { get }
    var isAnimating: Bool { get }
}

public extension EnvironmentValues {
    @Entry var appConfig = CrossConfig()
}
