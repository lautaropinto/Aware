//
//  OnboardingStepOne 2.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//


import SwiftUI
import SwiftData
import AwareData

struct OnboardingStepThree: View {
    let onContinue: (() -> Void)?
    
    @Query private var tags: [Tag]
    
    @State private var titleFinishedWriting = false
    @State private var didParagraphFinish = false
    
    
    let firstParagraph = "Starting a timer is a small act of awareness..."
    let secondParagraph = "Stopping it is honoring the time you gave..."
    let lastParagraph = "Every moment counts when you add to notice."
    
    var body: some View {
        VStack {
            TypewriterText(
                text: "Make Every Moment Count",
                showCursor: false,
                onComplete: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    titleFinishedWriting = true
                }
            })
            .multilineTextAlignment(.center)
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
                    delayBetweenTexts: 1.2,
                    keepCursorAfterFinish: false
                ) {
                    withAnimation(.spring(duration: 1.2)) { didParagraphFinish = true }
                }
                .fontDesign(.monospaced)
                .padding(.bottom)
            }
            
            Button("Start Timing") {
                onContinue?()
            }
            .buttonStyle(DefaultBigButton(color: .accent))
            .opacity(didParagraphFinish ? 1.0 : 0.0)
            .transition(.opacity)
        }
        .padding()
    }
}

#Preview {
    OnboardingStepOne() {}
}
