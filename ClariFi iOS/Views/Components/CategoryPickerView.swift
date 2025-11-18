//
//  CategoryPickerView.swift
//  ClariFi iOS
//
//  Category picker component for transaction editing
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(CategoryDefinition.allCategories, id: \.canonicalName) { category in
                    Button(action: {
                        selectedCategory = category.canonicalName
                        dismiss()
                    }) {
                        HStack {
                            // Category icon
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            // Category info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let parent = category.parentCategory {
                                    Text(parent.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Checkmark for selected category
                            if selectedCategory == category.canonicalName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category.displayName) category")
                    .accessibilityHint(selectedCategory == category.canonicalName ? "Currently selected" : "Tap to select")
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryPickerView(selectedCategory: .constant("food_groceries"))
}
