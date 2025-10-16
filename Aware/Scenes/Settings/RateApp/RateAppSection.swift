//
//  RateAppSection.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/16/25.
//

import SwiftUI
import StoreKit

struct RateAppSection: View {
    var body: some View {
        Section {
            Button {
                requestAppStoreReview()
            } label: {
                HStack {
                    Label("Rate the app", systemImage: "star.fill")
                        .labelStyle(ColorfulIcon(color: .accent))

                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .imageScale(.small)
                        .foregroundStyle(Color.secondary)
                }
            }
            .tint(.primary)
            .listRowBackground(Color.gray.opacity(0.1))
        } footer: {
            Text("Your support helps Aware grow")
                .italic()
        }
    }

    private func requestAppStoreReview() {
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
}

#Preview {
    RateAppSection()
}
