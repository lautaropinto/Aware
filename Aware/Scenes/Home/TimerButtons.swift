//
//  TimerButtons.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI

// MARK: - Button Components
//
//struct PlayPauseButton: View {
//    let isRunning: Bool
//    let hasElapsedTime: Bool
//    let onAction: () -> Void
//    
//    private var buttonText: String {
//        if isRunning {
//            return "Pause"
//        } else if hasElapsedTime {
//            return "Resume"
//        } else {
//            return "Start"
//        }
//    }
//    
//    private var buttonColor: Color {
//        if isRunning {
//            return .orange
//        } else {
//            return .green
//        }
//    }
//    
//    var body: some View {
//        Button(buttonText, action: onAction)
//            .buttonStyle(.borderedProminent)
//            .tint(buttonColor)
//            .clipShape(Capsule())
//            .animation(.easeInOut(duration: 0.2), value: buttonColor)
//    }
//}
//
//struct StopButton: View {
//    let isRunning: Bool
//    let onAction: () -> Void
//    
//    var body: some View {
//        Button("Stop", action: onAction)
//            .buttonStyle(StopButtonStyle(isRunning: isRunning))
//            .tint(.red)
//    }
//}
//
//struct StopButtonStyle: ButtonStyle {
//    let isRunning: Bool
//    
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(
//                Capsule()
//                    .fill(isRunning ? Color.red : Color.red.opacity(0.2))
//                    .animation(.easeInOut(duration: 0.2), value: isRunning)
//            )
//            .overlay(
//                Capsule()
//                    .stroke(Color.red, lineWidth: isRunning ? 0 : 1)
//                    .animation(.easeInOut(duration: 0.2), value: isRunning)
//            )
//            .foregroundColor(isRunning ? .white : .red)
//            .animation(.easeInOut(duration: 0.2), value: isRunning)
//            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
//            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//    }
//}
