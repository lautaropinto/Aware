//
//  AddTagButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import AwareData

struct AddTagButton: View {
    @Binding var mode: QuickStartSection.TagMode
    @State private var isShowingTagForm = false
    
    var body: some View {
        Button(action: {
            if mode == .play {
                isShowingTagForm = true
            } else {
                withAnimation { mode = .play }
            }
        }) {
            Image(systemName: mode == .play ? "plus" : "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isShowingTagForm) {
            TagForm()
        }
    }
}

#Preview {
    AddTagButton(mode: .constant(.play))
}
