//
//  ListRow.swift
//  AwareWatchApp
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import AwareData

struct ListRow: View {
    let tag: AwareData.Tag
    
    var body: some View {
        HStack(spacing: 12.0) {
            Circle()
                .fill(tag.swiftUIColor)
                .frame(width: 12, height: 12)
            
            Text(tag.name)
            Spacer()
        }
    }
}

#Preview {
    ListRow(tag: .init(name: "Sran"))
}
