//
//  AboutView.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

extension AboutListSection {
    struct AboutView: View {
        /// Upgrade the v at the end of the string every time we upload a new version of it to the AppStore
        @AppStorage("about-text-is-ftu-v1") var isFTU = true
        
        @State private var showingTextOpacity = 0.0
        
        private let firstParagraph = "Aware wasn't built to help you do more. It was built to remind you that time is always moving... \nAnd you're moving with it."
        private let secondParagraph = "Each timer is a small moment of awareness. A chance to give meaning to what you're doing, and to be truly present in it."
        private let thirdParagraph = "You don't need to control time, or chase it. \nYou only need to notice it."
        private let fourthParagraph = "Start with intention.\nEnd with presence."
        private let lastParagraph = "That's all Aware asks."
        
        var body: some View {
            NavigationStack {
                VStack {
                    Spacer()
                    
                    if isFTU {
                        AnimatedText()
                    } else {
                        PlainText()
                            .opacity(showingTextOpacity)
                    }
                }
                .padding()
                .navigationTitle("About Aware")
                .applyBackgroundGradient()
                .onAppear {
                    withAnimation(.spring(duration: 1.2).delay(0.6)) {
                        showingTextOpacity = 1
                    }
                }
            }
        }
        
        @ViewBuilder func AnimatedText() -> some View {
            ChainedTypewriterView(
                texts: [
                    firstParagraph,
                    secondParagraph,
                    thirdParagraph,
                    fourthParagraph,
                    lastParagraph,
                ],
                speed: 52,
                delayBetweenTexts: 1.0,
                keepCursorAfterFinish: false
            ) {
                isFTU = false
            }
            .fontDesign(.monospaced)
            .padding(.bottom)
        }
        
        @ViewBuilder func PlainText() -> some View {
            VStack(alignment: .leading, spacing: 20.0) {
                Text(firstParagraph)
                Text(secondParagraph)
                Text(thirdParagraph)
                Text(fourthParagraph)
                Text(lastParagraph)
            }
            .fontDesign(.monospaced)
            .padding(.bottom)
        }
    }
}

#Preview {
    AboutListSection.AboutView()
}
