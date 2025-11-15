//
//  DraggableTagGrid.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/14/25.
//
import SwiftUI
import SwiftData
import AwareData

struct DraggableTagGrid: View {
    let isDisabled: Bool
    let tagMode: QuickStartSection.TagMode
    @Binding var draggedTag: Tag?
    let onTagSelected: (Tag) -> Void
    
    @Environment(\.modelContext) var modelContext
    @Environment(Storage.self) var storage
    
    private var tags: [Tag] { storage.tags }
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tags, id: \.id) { tag in
                DraggableTagButton(
                    tag: tag,
                    isDisabled: isDisabled,
                    draggedTag: $draggedTag,
                    onTap: { onTagSelected(tag) },
                    onReorder: reorderTags,
                    tagMode: tagMode
                )
            }
        }
    }
    
    private func reorderTags(sourceTag: Tag, targetTag: Tag) {
        guard sourceTag.id != targetTag.id else { return }
        
        // Create a mutable copy of the current tags array
        var reorderedTags = Array(tags)
        
        // Find the indices
        guard let sourceIndex = reorderedTags.firstIndex(where: { $0.id == sourceTag.id }),
              let targetIndex = reorderedTags.firstIndex(where: { $0.id == targetTag.id }) else {
            return
        }
        
        // Remove the source tag and insert it at the target position
        let movedTag = reorderedTags.remove(at: sourceIndex)
        reorderedTags.insert(movedTag, at: targetIndex)
        
        // Reassign displayOrder values based on the new positions
        for (index, tag) in reorderedTags.enumerated() {
            tag.displayOrder = index
        }
        
        // Save the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to reorder tags: \(error)")
        }
    }
}

// MARK: - DraggableTagButton Component

struct DraggableTagButton: View {
    let tag: Tag
    let isDisabled: Bool
    @Binding var draggedTag: Tag?
    let onTap: () -> Void
    let onReorder: (Tag, Tag) -> Void
    let tagMode: QuickStartSection.TagMode
    
    @State private var isDragging = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: tag.image)
                    .imageScale(.small)
                    .foregroundStyle(isDisabled ? .secondary.opacity(0.86) : tag.swiftUIColor)
                
                Text(tag.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: tagMode.buttonIcon)
                    .imageScale(.small)
                    .foregroundStyle(tagMode.buttonIconColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isDragging ? 1.05 : (isDisabled ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .animation(.easeInOut(duration: 0.3), value: isDisabled)
        }
        .rounded()
//        .glassEffect(.regular.interactive(!isDisabled), in: .containerRelative)
        .disabled(isDisabled)
        .draggable(tag) {
            // Drag preview
            HStack {
                Circle()
                    .fill(tag.swiftUIColor)
                    .frame(width: 12, height: 12)
                
                Text(tag.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .dropDestination(for: Tag.self) { droppedTags, location in
            guard let droppedTag = droppedTags.first else { return false }
            onReorder(droppedTag, tag)
            return true
        } isTargeted: { isTargeted in
            // Visual feedback when drag is over this item
            withAnimation(.easeInOut(duration: 0.2)) {
                isDragging = isTargeted
            }
        }
        .onChange(of: draggedTag) { _, newValue in
            isDragging = newValue?.id == tag.id
        }
    }
}
