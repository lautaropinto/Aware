//
//  EmptyHistoryView.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import SwiftUI

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
        .rounded()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}
