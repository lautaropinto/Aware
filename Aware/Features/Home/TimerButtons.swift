//
//  TimerButtons.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI

// MARK: - Button Components

struct PlayPauseButton: View {
    let isRunning: Bool
    let hasElapsedTime: Bool
    let onAction: () -> Void
    
    private var buttonText: String {
        if isRunning {
            return "Pause"
        } else if hasElapsedTime {
            return "Resume"
        } else {
            return "Start"
        }
    }
    
    private var buttonSymbol: String {
        if isRunning {
            return "pause.fill"
        } else if hasElapsedTime {
            return "play.fill"
        } else {
            return "play.fill"
        }
    }
    
    private var buttonColor: Color {
        if isRunning {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        Button(action: onAction) {
            Image(systemName: buttonSymbol)
                .contentTransition(.symbolEffect)
        }
        .buttonStyle(WatchButtonStyle(color: buttonColor, prominent: true))
        .animation(.easeInOut(duration: 0.2), value: buttonColor)
    }
}

struct StopButton: View {
    let isRunning: Bool
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            Image(systemName: "stop.fill")
        }
        .buttonStyle(WatchButtonStyle(color: .red, prominent: isRunning))
    }
}

struct WatchButtonStyle: ButtonStyle {
    let color: Color
    let prominent: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(prominent ? color : color.opacity(0.2))
                    .animation(.easeInOut(duration: 0.2), value: prominent)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16.0)
                    .stroke(color, lineWidth: prominent ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: prominent)
            )
            .foregroundColor(prominent ? .white : color)
            .animation(.easeInOut(duration: 0.4), value: prominent)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
