//
//  OnboardingStepOne.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//

import SwiftUI

struct OnboardingStepOne: View {
    let onContinue: (() -> Void)?
    
    @State private var titleFinishedWriting = false
    @State private var didParagraphFinish = false
    
    let firstParagraph = "Time is only moving forward..."
    let secondParagraph = "Every second slips into the past..."
    let lastParagraph = "Aware is about noticing where those seconds go, and choosing to be present in them..."
    
    var body: some View {
        VStack {
            TypewriterText(
                text: "Welcome to Aware",
                showCursor: false,
                onComplete: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    titleFinishedWriting = true
                }
            })
                .font(.largeTitle)
                .fontDesign(.rounded)
                .bold()
            
            Spacer()
            
            if titleFinishedWriting {
                ChainedTypewriterView(
                    texts: [
                        firstParagraph,
                        secondParagraph,
                        lastParagraph,
                    ],
                    speed: 45,
                    delayBetweenTexts: 1.2
                ) {
                    withAnimation(.spring(duration: 1.2)) { didParagraphFinish = true }
                }
                .fontDesign(.monospaced)
                .padding(.bottom)
            }
            
            Button("Continue") {
                onContinue?()
            }
            .buttonStyle(DefaultBigButton(color: .accent))
            .glassEffect(.regular.interactive())
            .opacity(didParagraphFinish ? 1.0 : 0.0)
            .transition(.opacity)
        }
        .padding()
    }
}

#Preview {
    OnboardingStepOne() {}
}


