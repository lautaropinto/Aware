//
//  HistoryScene.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData

struct HistoryScene: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Timekeeper.creationDate, order: .reverse)]) private var allTimers: [Timekeeper]
    
    @State private var selectedTag: Tag?
    @Query private var tags: [Tag]
    
    // Filter timers based on tag selection
    private var filteredTimers: [Timekeeper] {
        guard let selectedTag = selectedTag else { return allTimers }
        return allTimers.filter { $0.mainTag?.id == selectedTag.id }
    }
    
    private var hasFilteredResults: Bool {
        !filteredTimers.isEmpty
    }
    
    private var isTagFilterActive: Bool {
        selectedTag != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tag Filter Section
                if !tags.isEmpty {
                    tagFilterSection
                }
                
                // Timer List
                timerListSection
            }   
            .navigationTitle("History")
            .applyBackgroundGradient()
        }
    }
    
    // MARK: - Computed Views
    
    private var tagFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFilterButton
                tagFilterButtons
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
    
    private var allFilterButton: some View {
        FilterButton(
            text: "All",
            isSelected: !isTagFilterActive,
            color: .primary,
            onTap: selectAllFilter
        )
    }
    
    private var tagFilterButtons: some View {
        ForEach(tags, id: \.id) { tag in
            TagFilterButton(
                tag: tag,
                isSelected: selectedTag?.id == tag.id,
                onTap: { selectTagFilter(tag) }
            )
        }
    }
    
    private var timerListSection: some View {
        Group {
            if hasFilteredResults {
                timerList
            } else {
                emptyStateView
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filteredTimers.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTag?.id)
    }
    
    private var timerList: some View {
        List {
            ForEach(filteredTimers, id: \.id) { timekeeper in
                timerRowView(for: timekeeper)
            }
        }
//        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .transition(.opacity)
    }
    
    private var emptyStateView: some View {
        EmptyHistoryView(hasSearch: isTagFilterActive)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func timerRowView(for timekeeper: Timekeeper) -> some View {
        RecentTimerRow(timekeeper: timekeeper)
//            .listRowSeparator(.hidden)
            .transition(.scale.combined(with: .opacity))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Delete", role: .destructive) {
                    deleteTimer(timekeeper)
                }
            }
    }
    
    // MARK: - Actions
    
    private func selectAllFilter() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTag = nil
        }
    }
    
    private func selectTagFilter(_ tag: Tag) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTag = selectedTag?.id == tag.id ? nil : tag
        }
    }
    
    private func deleteTimer(_ timer: Timekeeper) {
        withAnimation {
            modelContext.delete(timer)
            try? modelContext.save()
        }
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearch ? "tag" : "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(hasSearch ? "No Results Found" : "No Timer History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(hasSearch ? "Try selecting a different tag filter" : "Start timing activities to see them here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    HistoryScene()
        .modelContainer(for: [Timekeeper.self, Tag.self], inMemory: true)
}

// MARK: - Filter Button Components

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

extension Color {
    static var background: Color { 
        Color(.systemBackground)
    }
}
