//
//  AboutListSection.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI

struct AboutListSection: View {
    var body: some View {
        NavigationLink {
            AboutView()
        } label: {
            Text("About aware")
        }
        .listRowBackground(Color.gray.opacity(0.4))
    }
}

#Preview {
    AboutListSection()
}
