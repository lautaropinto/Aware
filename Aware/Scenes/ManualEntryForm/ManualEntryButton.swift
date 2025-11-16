//
//  ManualEntryButton.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/21/25.
//

import SwiftUI

struct ManualEntryButton: View {
    @State private var isManualEntryPresented = false

    var body: some View {
        Button {
            isManualEntryPresented = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.primary)
        }
        .sheet(isPresented: $isManualEntryPresented) {
            ManualEntryForm()
        }
    }
}