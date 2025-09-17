//
//  AddTagButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI

struct AddTagButton: View {
    @State private var isShowingTagForm = false
    
    var body: some View {
        Button(action: {
            isShowingTagForm = true
        }) {
            Image(systemName: "plus")
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
    AddTagButton()
}
