// BackgroundColorEnvironment.swift
import SwiftUI
import Observation

extension Animation {
    static let stopWatch: Animation = .spring(duration: 0.4, bounce: 0.2)
    static let background: Animation = .spring(duration: 0.86, bounce: 0.6, blendDuration: 0.7)
}


@Observable
public class CrossConfig {
    public var isTimerRunning: Bool = false
    public var backgroundColor = Color.accentColor

    public init(backgroundColor: SwiftUICore.Color = Color.accentColor) {
        self.backgroundColor = backgroundColor
    }
    
    public func updateColor(_ color: Color) {
        withAnimation(.background) {
            self.backgroundColor = color
        }
    }
}

public extension EnvironmentValues {
    @Entry var appConfig = CrossConfig()
}
