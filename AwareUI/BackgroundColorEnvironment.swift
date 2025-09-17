// BackgroundColorEnvironment.swift
import SwiftUI
import Observation

@Observable
public class CrossConfig {
    public var backgroundColor = Color.accentColor
    
    public init(backgroundColor: SwiftUICore.Color = Color.accentColor) {
        self.backgroundColor = backgroundColor
    }
}

public extension EnvironmentValues {
    @Entry var appConfig = CrossConfig()
}
