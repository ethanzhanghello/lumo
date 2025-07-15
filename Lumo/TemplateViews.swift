//
//  TemplateViews.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

// MARK: - Save Template View
// Note: SaveTemplateView is defined in MealPlanningView.swift to avoid duplication

// MARK: - Load Template View
struct LoadTemplateView: View {
    let onLoad: (MealPlanTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var showingConfirmation = false
    @State private var selectedTemplate: MealPlanTemplate?
    
    private let availableTags = ["Vegan", "Vegetarian", "Low Carb", "High Protein", "Budget", "Quick", "Family", "Healthy", "Gluten-Free", "Dairy-Free"]
    
    var filteredTemplates: [MealPlanTemplate] {
        var templates = appState.mealPlanTemplates
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.lowercased().contains(searchText.lowercased()) ||
                template.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        if let selectedTag = selectedTag {
            templates = templates.filter { template in
                template.tags.contains(selectedTag)
            }
        }
        
        return templates
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search Bar
                    searchSection
                    
                    // Tags Filter
                    tagsFilterSection
                    
                    // Templates List
                    templatesListSection
                }
                .padding()
            }
            .navigationTitle("Load Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .confirmationDialog(
            "Replace Current Plan",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                if let template = selectedTemplate {
                    onLoad(template)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will replace your current meal plan. Continue?")
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search templates...", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var tagsFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(
                    name: "All",
                    isSelected: selectedTag == nil,
                    onToggle: { _ in
                        selectedTag = nil
                    }
                )
                
                ForEach(availableTags, id: \.self) { tag in
                    TagChip(
                        name: tag,
                        isSelected: selectedTag == tag,
                        onToggle: { isSelected in
                            selectedTag = isSelected ? tag : nil
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var templatesListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTemplates, id: \.id) { template in
                    TemplateCard(
                        template: template,
                        onLoad: {
                            selectedTemplate = template
                            showingConfirmation = true
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let name: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: MealPlanTemplate
    let onLoad: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button("Load") {
                    onLoad()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lumoGreen)
                .cornerRadius(8)
            }
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.lumoGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.lumoGreen.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Meal Preview
            HStack {
                Text("\(template.meals.count) meals")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(template.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 