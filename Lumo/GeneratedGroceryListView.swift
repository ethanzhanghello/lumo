//
//  GeneratedGroceryListView.swift
//  Lumo
//
//  Created by Ethan on 7/11/25.
//

import SwiftUI

struct GeneratedGroceryListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var weekStartDate = Date()
    @State private var groceryListData: [String: [String]] = [:]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Week Selector
                    weekSelectorSection
                    
                    // Grocery List
                    groceryListSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .navigationTitle("Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.gray)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Generate") {
                    generateGroceryList()
                }
                .foregroundColor(.lumoGreen)
            }
        }
        .onAppear {
            generateGroceryList()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shopping List")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Automatically generated from your meal plan for the week.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Week Selector Section
    private var weekSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Button("Previous") {
                    weekStartDate = Calendar.current.date(byAdding: .day, value: -7, to: weekStartDate) ?? weekStartDate
                    generateGroceryList()
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
                
                Spacer()
                
                Text(weekRangeText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Next") {
                    weekStartDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
                    generateGroceryList()
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
            }
        }
    }
    
    private var weekRangeText: String {
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: endDate))"
    }
    
    // MARK: - Grocery List Section
    private var groceryListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shopping List")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if groceryListData.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(groceryListData.keys.sorted()), id: \.self) { category in
                        if let ingredients = groceryListData[category] {
                            CategorySection(category: category, items: ingredients)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No meals planned for this week")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Add meals to your meal plan to generate a shopping list")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions
    private func generateGroceryList() {
        groceryListData = mealManager.generateGroceryList(for: weekStartDate)
        print("Generated grocery list with \(groceryListData.values.flatMap { $0 }.count) items")
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.lumoGreen)
            
            LazyVStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    GroceryItemRow(item: item)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Grocery Item Row
struct GroceryItemRow: View {
    let item: String
    @State private var isChecked = false
    
    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .lumoGreen : .gray)
                    .font(.title3)
            }
            
            Text(item)
                .font(.subheadline)
                .foregroundColor(.white)
                .strikethrough(isChecked)
                .opacity(isChecked ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
} 