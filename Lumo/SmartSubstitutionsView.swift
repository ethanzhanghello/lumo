//
//  SmartSubstitutionsView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct SmartSubstitutionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SubstitutionViewModel()
    @State private var showingOutOfStockOnly = false
    @State private var selectedSubstitution: SmartSubstitution?
    @State private var showingSubstitutionDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Filter Toggle
                    filterSection
                    
                    // Substitutions List
                    if viewModel.isLoading {
                        loadingSection
                    } else if viewModel.substitutions.isEmpty {
                        emptySection
                    } else {
                        substitutionsList
                    }
                }
            }
            .navigationTitle("Smart Substitutions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadSubstitutions()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .onAppear {
            loadSubstitutions()
        }
        .onChange(of: showingOutOfStockOnly) {
            loadSubstitutions()
        }
        .sheet(isPresented: $showingSubstitutionDetail) {
            if let substitution = selectedSubstitution {
                SubstitutionDetailView(substitution: substitution)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Substitutions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Find alternatives when your preferred items are out of stock or unavailable.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            HStack {
                Toggle("Out of Stock Only", isOn: $showingOutOfStockOnly)
                    .foregroundColor(.white)
                    .toggleStyle(SwitchToggleStyle(tint: .lumoGreen))
                    .onChange(of: showingOutOfStockOnly) {
                        loadSubstitutions()
                    }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .lumoGreen))
                .scaleEffect(1.2)
            
            Text("Finding smart substitutions...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Section
    private var emptySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.lumoGreen)
            
            Text("No Substitutions Needed")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("All your items are available! 🎉")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Substitutions List
    private var substitutionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.substitutions, id: \.id) { substitution in
                    SubstitutionCard(substitution: substitution) {
                        selectedSubstitution = substitution
                        showingSubstitutionDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    private func loadSubstitutions() {
        if showingOutOfStockOnly {
            viewModel.loadOutOfStockSubstitutions()
        } else {
            viewModel.loadSubstitutions(for: appState.groceryList.groceryItems.map { $0.item })
        }
    }
}

// MARK: - Substitution Card
struct SubstitutionCard: View {
    let substitution: SmartSubstitution
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(substitution.originalItem.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(substitution.reason.rawValue)
                            .font(.caption)
                            .foregroundColor(.lumoGreen)
                    }
                    
                    Spacer()
                    
                    // Confidence Badge
                    Text("\(Int(substitution.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(confidenceColor)
                        .cornerRadius(8)
                }
                
                // Alternative Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Alternative:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    AlternativePreviewCard(item: substitution.suggestedItem)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("View All") {
                        onTap()
                    }
                    .font(.caption)
                    .foregroundColor(.lumoGreen)
                    
                    Spacer()
                    
                    Button("Apply First") {
                        // TODO: Apply first alternative
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.lumoGreen)
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private var confidenceColor: Color {
        if substitution.confidence >= 0.8 {
            return .green
        } else if substitution.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Alternative Preview Card
struct AlternativePreviewCard: View {
    let item: GroceryItem
    
    var body: some View {
        HStack(spacing: 8) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption2)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(String(format: "$%.2f", item.price))
                    .font(.caption2)
                    .foregroundColor(.lumoGreen)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Substitution Detail View
struct SubstitutionDetailView: View {
    let substitution: SmartSubstitution
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedAlternative: GroceryItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original Item
                        originalItemSection
                        
                        // Alternatives
                        alternativesSection
                        
                        // Confidence Info
                        confidenceSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Substitution Details")
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
        .sheet(item: $selectedAlternative) { alternative in
            AlternativeDetailView(
                originalItem: substitution.originalItem,
                alternative: alternative,
                reason: substitution.reason.rawValue
            )
        }
    }
    
    // MARK: - Original Item Section
    private var originalItemSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Original Item")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Item Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(substitution.originalItem.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(substitution.originalItem.brand)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "$%.2f", substitution.originalItem.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lumoGreen)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Alternatives Section
    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alternatives")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                AlternativeDetailCard(
                    alternative: substitution.suggestedItem,
                    reason: substitution.reason.rawValue
                ) {
                        selectedAlternative = substitution.suggestedItem
                    }
                }
            }
        }
    }
    
    // MARK: - Confidence Section
    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why This Substitution?")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.lumoGreen)
                    
                    Text(substitution.reason.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.lumoGreen)
                    
                    Text("Confidence: \(Int(substitution.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Alternative Detail Card
struct AlternativeDetailCard: View {
    let alternative: GroceryItem
    let reason: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Item Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alternative.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(alternative.brand)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.lumoGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", alternative.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lumoGreen)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Alternative Detail View
struct AlternativeDetailView: View {
    let originalItem: GroceryItem
    let alternative: GroceryItem
    let reason: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Alternative Item Details
                        alternativeDetailsSection
                        
                        // Comparison
                        comparisonSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Alternative Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            })
        }
    }
    
    // MARK: - Alternative Details Section
    private var alternativeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alternative Item")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Item Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(alternative.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(alternative.brand)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "$%.2f", alternative.price))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.lumoGreen)
                    
                    Text(alternative.category)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ComparisonRow(
                    label: "Price",
                    original: String(format: "$%.2f", originalItem.price),
                    alternative: String(format: "$%.2f", alternative.price),
                    isBetter: alternative.price < originalItem.price
                )
                
                ComparisonRow(
                    label: "Category",
                    original: originalItem.category,
                    alternative: alternative.category,
                    isBetter: nil
                )
                
                ComparisonRow(
                    label: "Brand",
                    original: originalItem.brand,
                    alternative: alternative.brand,
                    isBetter: nil
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Replace with Alternative") {
                replaceItem()
                dismiss()
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.lumoGreen)
            .cornerRadius(12)
            
            Button("Add Alternative to List") {
                if let selectedStore = appState.selectedStore {
                    appState.groceryList.addItem(alternative, store: selectedStore)
                    dismiss()
                }
            }
            .foregroundColor(.lumoGreen)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.lumoGreen.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    private func replaceItem() {
        if let selectedStore = appState.selectedStore {
            appState.groceryList.removeItem(originalItem, store: selectedStore)
            appState.groceryList.addItem(alternative, store: selectedStore)
        }
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let label: String
    let original: String
    let alternative: String
    let isBetter: Bool?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Text(original)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.gray)
                .font(.caption)
            
            Text(alternative)
                .font(.subheadline)
                .foregroundColor(isBetter == true ? .lumoGreen : (isBetter == false ? .red : .white))
                .frame(maxWidth: .infinity, alignment: .center)
            
            if let isBetter = isBetter {
                Image(systemName: isBetter ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isBetter ? .green : .red)
                    .font(.caption)
            }
        }
    }
} 