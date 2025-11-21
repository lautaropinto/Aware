//
//  HistoryFilter.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/16/25.
//

import SwiftUI
import AwareData

struct HistoryFilter: View {
    @Environment(Storage.self) private var storage
    @Environment(HistoryStore.self) private var history
    
    private var tags: [Tag] {
        storage.tags
    }
    
    private var selectedTag: Tag? {
        history.filterBy
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(
                    text: "All",
                    isSelected: selectedTag == nil,
                    color: .primary,
                    onTap: { history.filterBy = nil }
                )
                
                ForEach(tags, id: \.id) { tag in
                    TagFilterButton(
                        tag: tag,
                        isSelected: selectedTag?.id == tag.id,
                        onTap: { history.filterBy = tag }
                    )
                }
            }
            .rounded()
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    HistoryFilter()
}
