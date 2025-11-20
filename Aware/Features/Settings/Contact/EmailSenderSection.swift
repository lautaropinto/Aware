//
//  EmailSenderView.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//

import SwiftUI
import OSLog

struct EmailSenderSection: View {
    let recipientEmail = "ar.lautaropinto@gmail.com"
    let emailSubject = "About time - feedback for Aware app"
    let emailBody = "Hi,\n\nJust wanted to share a reflection or some feedback about Aware\n\n--\n\n(Write freely. There's no right or wrong, only what you noticed.)\n\n[Your name]"

    var body: some View {
        Section {
            Button {
                sendEmail()
            } label: {
                HStack {
                    Label("Feedback / Contact", systemImage: "envelope.fill")
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
            Text("Your thoughts shape Aware")
                .italic()
        }
    }

    func sendEmail() {
        // Construct the mailto URL
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipientEmail

        // Add subject and body as query items
        components.queryItems = [
            URLQueryItem(name: "subject", value: emailSubject),
            URLQueryItem(name: "body", value: emailBody)
        ]

        // Ensure the URL is valid before attempting to open
        if let mailtoURL = components.url {
            // Check if the device can open the URL (i.e., has a mail client)
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL, options: [:], completionHandler: nil)
            } else {
                // Handle cases where no mail client is available
                print("No email client found or cannot open mailto URL.")
                // You might want to show an alert to the user here
            }
        }
    }
}
