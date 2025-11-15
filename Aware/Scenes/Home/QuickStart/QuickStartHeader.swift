//
//  QuickStartHeader.swift
//  Aware
//
//  Created by Lautaro Pinto on 11/14/25.
//

import SwiftUI

struct QuickStartHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Set Your Intention")
                .font(.title3)
                .fontWeight(.semibold)
//                .foregroundColor(isDisabled ? .secondary : .primary)
//                .animation(.easeInOut(duration: 0.3), value: isDisabled)
            
//            Spacer()
            
//            HStack {
//                EditModeButton()
//                DeleteModeButton()
//            }
            
//            AddTagButton(mode: $tagMode)
//                .disabled(isDisabled)
        }
    }
}

#Preview {
    QuickStartHeader()
}
