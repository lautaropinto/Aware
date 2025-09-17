//
//  TagForm.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/8/25.
//

import SwiftUI
import SwiftData
import AwareData
import SFSymbolPicker

struct TagForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingTags: [Tag]
    
    @State private var tagName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var tagImage: String = "tag"
    @State private var showingImagePicker: Bool = false
    
    private var isSaveEnabled: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Predefined colors for easy selection
    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Tag Name Section
                HStack(spacing: 8) {
                    Image(systemName: tagImage)
                        .onTapGesture {
                            showingImagePicker = true
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            SFSymbolPicker(selection: $tagImage)
                        }
                    
                    TextField("Enter tag name", text: $tagName)
                        .font(.body)
                }
                
                // Color Picker Section
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Color Preview
                    HStack {
                        Text("Tag Color")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(tagName.isEmpty ? "Preview" : tagName)
                            .font(.subheadline)
                            .foregroundColor(selectedColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedColor.opacity(0.1))
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    
                    // Color Options Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Array(colorOptions.enumerated()), id: \.offset) { index, color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                            .frame(width: 36, height: 36)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Custom Color Picker
                    ColorPicker("Custom Color", selection: $selectedColor)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveTag) {
                    Text("Save Tag")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSaveEnabled ? selectedColor : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isSaveEnabled)
                .animation(.easeInOut(duration: 0.2), value: isSaveEnabled)
            }
            .padding(24)
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(42)
    }
    
    private func saveTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Convert Color to hex string
        let hexColor = selectedColor.toHex()
        
        // Calculate the next display order (append to end)
        let maxOrder = existingTags.map(\.displayOrder).max() ?? -1
        let nextOrder = maxOrder + 1
        
        let newTag = Tag(name: trimmedName, color: hexColor, image: tagImage, displayOrder: nextOrder)
        modelContext.insert(newTag)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error if needed
            print("Failed to save tag: \(error)")
        }
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06X", rgb)
    }
}

#Preview {
    TagForm()
        .modelContainer(for: [Tag.self], inMemory: true)
}
