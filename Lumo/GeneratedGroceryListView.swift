//
//  GeneratedGroceryListView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct GeneratedGroceryListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    @StateObject private var groceryList = GeneratedGroceryList()
    
    @State private var weekStartDate = Date()
    @State private var showingAddToGroceryList = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if groceryList.items.isEmpty {
                            emptyStateView
                        } else {
                            groceryListSection
                        }
                        
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
        }
        .onAppear {
            generateGroceryList()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Shopping List")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Based on your meal plan for this week")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No items in shopping list")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Generate a shopping list from your meal plan")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Grocery List Section
    private var groceryListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shopping List")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Add to Grocery List") {
                    showingAddToGroceryList = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                    if let items = groupedItems[category] {
                        CategorySection(category: category, items: items)
                    }
                }
            }
        }
    }
    
    private var groupedItems: [String: [GeneratedGroceryItem]] {
        Dictionary(grouping: groceryList.items) { $0.category }
    }
    
    private func generateGroceryList() {
        groceryList.items.removeAll()
        
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: weekStartDate)?.start ?? weekStartDate
        let groceryListData = mealManager.generateGroceryList(for: weekStart)
        
        for (category, ingredients) in groceryListData {
            for ingredient in ingredients {
                let item = GeneratedGroceryItem(name: ingredient, quantity: 1, category: category)
                groceryList.addItem(item)
            }
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: String
    let items: [GeneratedGroceryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(items, id: \.id) { item in
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
    let item: GeneratedGroceryItem
    @State private var isCompleted = false
    
    var body: some View {
        HStack {
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .lumoGreen : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .strikethrough(isCompleted)
                
                Text("\(item.quantity) item\(item.quantity == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(item.category)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Grocery Item Model
struct GeneratedGroceryItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Int
    let category: String
}

// MARK: - Grocery List Model
class GeneratedGroceryList: ObservableObject {
    @Published var items: [GeneratedGroceryItem] = []
    
    func addItem(_ item: GeneratedGroceryItem) {
        items.append(item)
    }
    
    func removeItem(_ item: GeneratedGroceryItem) {
        items.removeAll { $0.id == item.id }
    }
}

#Preview {
    GeneratedGroceryListView()
} 