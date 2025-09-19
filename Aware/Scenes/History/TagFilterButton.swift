//
//  TagFilterButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import SwiftUI
import AwareData

struct TagFilterButton: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? tag.swiftUIColor.opacity(0.2) : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? tag.swiftUIColor : Color.primary)
                .clipShape(Capsule())
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct FilterButton: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? Color.background : Color.primary)
                .clipShape(Capsule())
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
