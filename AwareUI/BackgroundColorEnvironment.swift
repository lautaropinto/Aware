// BackgroundColorEnvironment.swift
import SwiftUI
import Observation

@Observable
public class CrossConfig {
    public var isTimerRunning: Bool = false
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

    var meshPoints: [SIMD2<Float>] { get }
    var meshColors: [Color] { get }
}

public extension EnvironmentValues {
    @Entry var appConfig = CrossConfig()
}
