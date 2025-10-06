//
//  TitleWithCloseButtonModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//


//
//  TitleWithCloseButtonModifier.swift
//  Sentimo
//
//  Created by Lautaro Pinto on 6/6/25.
//

import SwiftUI

typealias DisplayMode = NavigationBarItem.TitleDisplayMode

private struct TitleWithCloseButtonModifier: ViewModifier {
    let title: String
    let displayMode: DisplayMode
    
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary)
                            .imageScale(.large)
                    }
                }
            }
    }
}

extension View {
    func navigationTitleWithCloseButton(_ title: String, displayMode: DisplayMode = .inline) -> some View {
        modifier(TitleWithCloseButtonModifier(title: title, displayMode: displayMode))
    }
}
