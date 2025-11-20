//
//  IconPicker.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/17/25.
//

import SwiftUI
import SFSymbolPicker

struct TagIconPicker: View {
    @Binding var selection: String
    
    @State private var showingImagePicker: Bool = false
    
    var body: some View {
        Button {
            showingImagePicker = true
        } label: {
            Image(systemName: selection)
                .imageScale(.small)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .sheet(isPresented: $showingImagePicker) {
            SFSymbolPicker(selection: $selection)
        }
    }
}

