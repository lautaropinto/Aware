//
//  QuickStartSection.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData

struct QuickStartSection: View {
    @Query(sort: \Tag.displayOrder) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    let isDisabled: Bool
    let onTagSelected: (Tag) -> Void
    
    @State private var draggedTag: Tag?
    @State private var tagMode: TagMode = .play
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: Tag?
    @State private var tagToEdit: Tag?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Set Your Intention")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.3), value: isDisabled)
                
                Spacer()
                
                HStack {
                    EditModeButton()
                    DeleteModeButton()
                }
                
                AddTagButton(mode: $tagMode)
                    .disabled(isDisabled)
            }
            
            DraggableTagGrid(
                tags: tags,
                isDisabled: isDisabled,
                tagMode: tagMode,
                draggedTag: $draggedTag,
                onTagSelected: { tag in
                    if !isDisabled {
                        switch tagMode {
                        case .play:
                            onTagSelected(tag)
                        case .delete:
                            onDelete(tag)
                        case .edit:
                            onEdit(tag)
                        }
                    }
                },
                onReorder: { sourceTag, targetTag in
                    reorderTags(sourceTag: sourceTag, targetTag: targetTag)
                }
            )
        }
        .rounded()
        .alert("Delete activity", isPresented: $showingDeleteAlert) {
            DeleteAlert
        } message: {
            Text(
                "Are you sure you want to delete this activity and its related timers? This action cannot be undone."
            )
        }
        .sheet(item: $tagToEdit, onDismiss: {
            tagToEdit = nil
        }) { tag in
            TagForm(tagToEdit: tag)
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
    
    private func onDelete(_ tag: Tag) {
        tagToDelete = tag
        showingDeleteAlert = true
    }
    
    private func onEdit(_ tag: Tag) {
        tagToEdit = tag
    }
    
    @ViewBuilder
    func DeleteModeButton() -> some View {
        Button(action: {
            withAnimation { tagMode = .delete }
        }) {
            Image(systemName: "trash")
                .imageScale(.small)
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(CircledSmallButton(color: .red))
        .disabled(isDisabled)
    }
    
    @ViewBuilder
    func EditModeButton() -> some View {
        Button(action: {
            withAnimation { tagMode = .edit }
        }) {
            Image(systemName: "pencil")
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(CircledSmallButton(color: .yellow))
        .disabled(isDisabled)
    }
    
    @ViewBuilder
    private var DeleteAlert: some View {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
            guard let tagToDelete else { return }
            withAnimation {
                modelContext.delete(tagToDelete)
                
                self.tagToDelete = nil
            }
        }
    }
    
    enum TagMode {
        case play, delete, edit
        
        var color: Color {
            switch self {
            case .play: return .clear
            case .delete: return .red
            case .edit: return .yellow
            }
        }
        
        var buttonIconColor: Color {
            switch self {
            case .play: return .secondary.opacity(0.3)
            case .delete: return .red
            case .edit: return .yellow
            }
        }
        
        var buttonIcon: String {
            switch self {
            case .play: return "play.fill"
            case .delete: return "trash"
            case .edit: return "pencil"
            }
        }
    }
}

// MARK: - DraggableTagGrid Component

struct DraggableTagGrid: View {
    let tags: [Tag]
    let isDisabled: Bool
    let tagMode: QuickStartSection.TagMode
    @Binding var draggedTag: Tag?
    let onTagSelected: (Tag) -> Void
    let onReorder: (Tag, Tag) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tags, id: \.id) { tag in
                DraggableTagButton(
                    tag: tag,
                    isDisabled: isDisabled,
                    draggedTag: $draggedTag,
                    onTap: { onTagSelected(tag) },
                    onReorder: onReorder,
                    tagMode: tagMode
                )
            }
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
        .glassEffect(.regular.interactive(!isDisabled), in: .containerRelative)
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

// MARK: - Tag Transferable Conformance

extension Tag: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
