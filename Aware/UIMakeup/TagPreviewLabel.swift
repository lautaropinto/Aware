//
//  TagPreviewLabel.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/15/25.
//

import SwiftUI
import AwareData

struct TagPreviewLabel: View {
    let tag: AwareData.Tag
    var body: some View {
        Label(tag.name.isEmpty ? "Preview" : tag.name, systemImage: tag.image)
            .imageScale(.small)
            .font(.subheadline)
            .foregroundColor(tag.swiftUIColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                tag.swiftUIColor.opacity(0.1)
                    .clipShape(.capsule)
            )
            .glassEffect(.clear, in: .capsule)
            .cornerRadius(8)
    }
}

#Preview {
    TagPreviewLabel(tag: .init(name: "sran"))
}
