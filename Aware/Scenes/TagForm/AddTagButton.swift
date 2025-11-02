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
                .foregroundColor(.background)
        }
//        .frame(width: 30.0, height: 30.0)
//        .buttonStyle(.borderedProminent)
//        .tint(.primary)
//        .clipShape(Circle())
        .sheet(isPresented: $isShowingTagForm) {
            TagForm()
        }
        .buttonStyle(CircledSmallButton(color: .primary))
    }
}

#Preview {
    AddTagButton(mode: .constant(.play))
}
