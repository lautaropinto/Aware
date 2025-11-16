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
    @Environment(\.appConfig) private var appConfig
    @Environment(LiveActivityStore.self) private var liveActivity
    @Environment(Storage.self) private var storage
    
    @State private var draggedTag: Tag?
    @State private var tagMode: TagMode = .play
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: Tag?
    @State private var tagToEdit: Tag?
    
    var isDisabled: Bool {
        appConfig.isTimerRunning
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuickStartHeader()
            
            DraggableTagGrid(
                isDisabled: isDisabled,
                tagMode: tagMode,
                draggedTag: $draggedTag,
                onTagSelected: { tag in
                    withAnimation(.stopWatch) {
                        if !isDisabled {
                            switch tagMode {
                            case .play:
                                createAndStartTimer(with: tag)
                            case .delete:
                                onDelete(tag)
                            case .edit:
                                onEdit(tag)
                            }
                        }
                    }
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
//                modelContext.delete(tagToDelete)
                
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
    
    private func createAndStartTimer(with tag: Tag) {
        storage.startNewTimer(with: tag)
        liveActivity.timer = storage.timer
        liveActivity.startLiveActivity(with: storage.timer)
        if let timer = storage.timer {
            withAnimation(.background) {
                appConfig.backgroundColor = timer.swiftUIColor
                appConfig.isTimerRunning = true
            }
        }
    }
}

// MARK: - Tag Transferable Conformance

extension Tag: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
