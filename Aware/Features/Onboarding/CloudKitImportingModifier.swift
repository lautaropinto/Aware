//
//  CloudKitImportingModifier.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/19/25.
//

import SwiftUI
import CoreData

private struct CloudKitImportingModifier: ViewModifier {
    @Binding var isCloudkitImporting: Bool
    
    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSPersistentCloudKitContainer.eventChangedNotification
                )
                .receive(on: RunLoop.main)
            ) { notification in
                
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
                    return
                }
                
                if event.type == .import {
                    isCloudkitImporting = true
                }
                
                if event.endDate != nil && event.type == .import {
                    isCloudkitImporting = false
                }
            }
    }
}

extension View {
    public func cloudKitImporting(_ isCloudkitImporting: Binding<Bool>) -> some View {
        modifier(CloudKitImportingModifier(isCloudkitImporting: isCloudkitImporting))
    }
}
