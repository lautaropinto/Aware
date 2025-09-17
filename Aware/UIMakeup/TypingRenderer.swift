//
//  TypingRenderer.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/13/25.
//

import SwiftUI

private struct TypewriterTextRenderer: TextRenderer {
    let visibleCharCount: Int
    let showCursor: Bool
    let keepCursorAfterFinish: Bool
    let totalCharCount: Int
    let cursorVisible: Bool
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var currentCharIndex = 0
        var lastGlyphBounds: CGRect?
        
        for line in layout {
            for run in line {
                for glyph in run {
                    if currentCharIndex < visibleCharCount {
                        context.draw(glyph)
                        // Track the bounds of the last drawn character
                        lastGlyphBounds = glyph.typographicBounds.rect
                    }
                    currentCharIndex += 1
                }
            }
        }
        
        // Draw cursor if showCursor is true and either:
        // 1. We're still typing, OR
        // 2. We're finished but keepCursorAfterFinish is true
        let shouldShowCursor = showCursor && (
            visibleCharCount < totalCharCount ||
            (visibleCharCount >= totalCharCount && keepCursorAfterFinish)
        )
        
        if shouldShowCursor, let bounds = lastGlyphBounds {
            // Position cursor at the end of the last visible character
            let cursorX = bounds.maxX + 2 // Small gap after last character
            let cursorY = bounds.minY
            let cursorHeight = bounds.height
            
            let cursorRect = CGRect(
                x: cursorX,
                y: cursorY,
                width: 2,
                height: cursorHeight
            )
            
            // Cursor behavior: solid while typing, blinking when finished
            let opacity: Double
            if visibleCharCount < totalCharCount {
                // Still typing - solid cursor
                opacity = 1.0
            } else {
                // Finished typing - use cursorVisible state for blinking
                opacity = cursorVisible ? 1.0 : 0.0
            }
            
            context.fill(
                Path(cursorRect),
                with: .color(.primary.opacity(opacity))
            )
        }
    }
}

struct TypewriterText: View {
    let text: String
    let speed: Double // Characters per second
    let showCursor: Bool
    let keepCursorAfterFinish: Bool
    let onComplete: (() -> Void)? // Callback when animation completes
    
    @State private var visibleCharCount = 0
    @State private var timer: Timer?
    @State private var blinkTimer: Timer?
    @State private var cursorVisible = true
    
    init(
        text: String,
        speed: Double = 15,
        showCursor: Bool = true,
        keepCursorAfterFinish: Bool = false,
        onComplete: (() -> Void)? = nil
    ) {
        self.text = text
        self.speed = speed
        self.showCursor = showCursor
        self.keepCursorAfterFinish = keepCursorAfterFinish
        self.onComplete = onComplete
    }
    
    var body: some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .textRenderer(TypewriterTextRenderer(
                visibleCharCount: visibleCharCount,
                showCursor: showCursor,
                keepCursorAfterFinish: keepCursorAfterFinish,
                totalCharCount: text.count,
                cursorVisible: cursorVisible
            ))
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                timer?.invalidate()
                blinkTimer?.invalidate()
            }
    }
    
    private func startAnimation() {
        timer?.invalidate()
        blinkTimer?.invalidate()
        visibleCharCount = 0
        cursorVisible = true
        
        let interval = 1.0 / speed
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if visibleCharCount < text.count {
                visibleCharCount += 1
            } else {
                timer?.invalidate()
                // Start blinking when typing is finished
                if keepCursorAfterFinish || showCursor {
                    startBlinking()
                }
                // Call completion callback
                onComplete?()
            }
        }
    }
    
    private func startBlinking() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }
}

// MARK: - Chained Typewriter for Sequential Text

struct ChainedTypewriterView: View {
    let texts: [String]
    let speed: Double
    let delayBetweenTexts: Double
    let showCursor: Bool
    let keepCursorAfterFinish: Bool
    let onComplete: (() -> Void)? // Callback when entire chain completes
    
    @State private var visibleTextIndices: Set<Int> = []
    @State private var completedTextIndices: Set<Int> = []
    @State private var currentActiveIndex: Int = 0 // Track which text should show cursor
    
    init(texts: [String], speed: Double = 15, delayBetweenTexts: Double = 2.0, showCursor: Bool = true, keepCursorAfterFinish: Bool = true, onComplete: (() -> Void)? = nil) {
        self.texts = texts
        self.speed = speed
        self.delayBetweenTexts = delayBetweenTexts
        self.showCursor = showCursor
        self.keepCursorAfterFinish = keepCursorAfterFinish
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("")
                Spacer()
            }
            ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                if visibleTextIndices.contains(index) {
                    TypewriterText(
                        text: text,
                        speed: speed,
                        showCursor: showCursor && (index == currentActiveIndex), // Only show cursor on active text
                        keepCursorAfterFinish: index == texts.count - 1 ? keepCursorAfterFinish : true, // Keep blinking during delays
                        onComplete: {
                            completedTextIndices.insert(index)
                            
                            // Check if this was the last text
                            if index == texts.count - 1 {
                                // All texts completed - call the chain's onComplete
                                onComplete?()
                            } else {
                                // Start next text after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenTexts) {
                                    currentActiveIndex = index + 1 // Move cursor to next text
                                    visibleTextIndices.insert(index + 1)
                                }
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            // Start with first text
            if !texts.isEmpty {
                currentActiveIndex = 0
                visibleTextIndices.insert(0)
            }
        }
    }
}
