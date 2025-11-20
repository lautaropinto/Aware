//
//  ManualEntryForm.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/21/25.
//

import SwiftUI
import SwiftData
import AwareData

extension ManualEntryButton {
    struct ManualEntryForm: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.dismiss) private var dismiss
        
        @Query private var tags: [Tag]
        
        @State private var selectedTag: Tag?
        @State private var startTime = Date()
        @State private var endTime = Date()
        
        private var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
        
        private var canSave: Bool {
            selectedTag != nil && duration > 0
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    IntentionPicker()
                        .listRowBackground(Color.clear)
                        .rounded()
                    
                    Section {
                        DatePicker("Started at", selection: $startTime)
                        DatePicker("Ended at", selection: $endTime)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    .rounded()
                    
                    HStack {
                        Text("Time spent")
                            .foregroundStyle(.secondary)
                        Text(duration.compactFormattedTime)
                            .bold()
                        Spacer()
                    }
                    .italic()
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
                }
                .listSectionSpacing(4.0)
                .scrollContentBackground(.hidden)
                .presentationDetents([.fraction(0.46)])
                .navigationTitle("Add a session")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .rounded()
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveTimer()
                        }
                        .disabled(!canSave)
                        .rounded()
                    }
                }
            }
        }
        
        @ViewBuilder private func IntentionPicker() -> some View {
            Picker("Intention", selection: $selectedTag) {
                Text(" - ").tag(nil as Tag?)
                
                ForEach(tags, id: \.id) { tag in
                    Label(tag.name, systemImage: tag.image.isEmpty ? "circle.fill" : tag.image)
                        .imageScale(.small)
                        .foregroundColor(tag.swiftUIColor)
                        .tag(tag as Tag?)
                }
            }
        }
        
        private func saveTimer() {
            guard let selectedTag = selectedTag, duration > 0 else { return }
            
            let timer = Timekeeper(name: selectedTag.name, tags: [selectedTag])
            timer.creationDate = startTime
            timer.startTime = startTime
            timer.endTime = endTime
            timer.totalElapsedSeconds = duration
            timer.isRunning = false
            
            modelContext.insert(timer)
            
            do {
                try modelContext.save()
                dismiss()
            } catch {
                print("Failed to save timer: \(error)")
            }
        }
    }
}
