//
//  QuickTagForm.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/15/25.
//

import SwiftUI
import AwareData
import SFSymbolPicker

struct QuickTagForm: View {
    @Binding var tags: [AwareData.Tag]
    
    @State private var currentTagIcon = "heart.fill"
    @State private var currentColorPicking: Color = .accent
    @State private var currentTagText = ""
    
    @Namespace var namespace
    
    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading) {
                WrappingLayout(spacing: 8.0) {
                    ForEach(tags) { tag in
                        TagPreviewLabel(tag: tag)
                            .overlay(alignment: .topTrailing) {
                                Button("", systemImage: "xmark.circle.fill") {
                                    removeTag(tag)
                                }
                                .frame(width: 12.0, height: 12.0)
                                .offset(x: 6.0, y: -6.0)
                                .tint(.gray)
                                .glassEffect(.identity, in: .circle)
                            }
                            .glassEffectID("pill", in: namespace)
                    }
                }
                
                HStack(spacing: 16.0) {
                    ColorPicker("", selection: $currentColorPicking)
                        .frame(maxWidth: 16.0)
                    
                    TagIconPicker(selection: $currentTagIcon)
                        .tint(currentColorPicking)
                    
                    TextField("Working out", text: $currentTagText)
                        .onSubmit {
                            addTag()
                        }
                    
                    Spacer()
                    
                    Button("Add", systemImage: "plus") {
                        addTag()
                    }
                    .disabled(currentTagText.isEmpty)
                    .tint(currentColorPicking)
                }
                .padding()
                .glassEffect(.clear)
                .glassEffectID("form", in: namespace)
            }
        }
    }
    
    private func addTag() {
        guard !currentTagText.isEmpty else { return }
        
        let newTag = Tag(
            name: currentTagText,
            color: currentColorPicking.toHex(),
            image: currentTagIcon,
            displayOrder: 0
        )
        withAnimation { tags.append(newTag) }
        currentTagText = ""
        currentColorPicking = .accent
        currentTagIcon = "heart.fill"
    }
    
    private func removeTag(_ tag: Tag) {
        guard let indexOfTagToRemove = tags.firstIndex(of: tag) else { return }
        
        withAnimation { _ = tags.remove(at: indexOfTagToRemove) }
    }
    
    @ViewBuilder
    private func IconPicker() -> some View {
        
    }
}

#Preview {
    @Previewable @State var tags: [AwareData.Tag] = []
    
    QuickTagForm(
        tags: $tags
    )
}

