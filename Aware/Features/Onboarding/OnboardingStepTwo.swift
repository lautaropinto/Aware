//
//  OnboardingStepOne 2.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//


import SwiftUI
import SwiftData
import AwareData

struct OnboardingStepTwo: View {
    let onContinue: (() -> Void)?
    
    @Query private var storedTags: [AwareData.Tag]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var titleFinishedWriting = false
    @State private var didParagraphFinish = false
    @State private var createdTags: [AwareData.Tag] = []
    
    private let firstParagraph = "Every timer begins with a choice..."
    private let secondParagraph = "Work, rest, create, connect — what matters most to you?.."
    private let lastParagraph = "Add or remove activities to reflect your life. These are the anchors for your time..."
    
    var body: some View {
        VStack {
            TypewriterText(
                text: "Give Your Time a Name",
                showCursor: false,
                onComplete: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    titleFinishedWriting = true
                }
            })
                .font(.largeTitle)
                .fontDesign(.rounded)
                .bold()
            
            if titleFinishedWriting {
                ChainedTypewriterView(
                    texts: [
                        firstParagraph,
                        secondParagraph,
                        lastParagraph
                    ],
                    speed: 45,
                    delayBetweenTexts: 1.2
                ) {
                    withAnimation(.spring(duration: 2.0)) { didParagraphFinish = true }
                }
                .fontDesign(.monospaced)
                .padding(.bottom)
            }
            
            QuickTagForm(tags: $createdTags)
                .opacity(didParagraphFinish ? 1.0 : 0.0)
            
            Spacer()
            
            
            Button("Next") {
                nextButton()
            }
            .buttonStyle(DefaultBigButton(color: .accent))
            .opacity(didParagraphFinish ? 1.0 : 0.0)
            .transition(.opacity)
            .disabled(createdTags.isEmpty)
        }
        .padding()
        .onAppear {
            createdTags.append(contentsOf: storedTags)
        }
    }
    
    func nextButton() {
        createdTags.forEach {
            modelContext.insert($0)
        }
        
        onContinue?()
    }
}

#Preview {
    OnboardingStepOne() {}
}
