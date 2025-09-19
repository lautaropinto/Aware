//
//  TagIconView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import SwiftUI
import AwareData

struct TagIconView: View {
    let tag: Tag
    var body: some View {
        Image(systemName: tag.image)
            .imageScale(.small)
            .foregroundStyle(Color.primary)
            .padding(8.0)
            .background(
                Circle()
                    .fill(tag.swiftUIColor.gradient)
                    .frame(width: 32.0, height: 32.0)
            )
    }
}
