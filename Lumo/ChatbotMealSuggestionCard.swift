//
//  ChatbotMealSuggestionCard.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct ChatbotMealSuggestionCard: View {
    let recipe: Recipe
    let suggestedDate: Date
    let suggestedMealType: MealType
    let onAddToMealPlan: () -> Void
    let onAddToGroceryList: () -> Void
    let onViewRecipe: () -> Void
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var selectedMealType: MealType = .dinner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipe Header
            HStack(spacing: 12) {
                // Recipe Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                        Label("\(recipe.totalTime) min", systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: {
                    selectedDate = suggestedDate
                    selectedMealType = suggestedMealType
                    showingDatePicker = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption)
                        
                        Text("Add to Meal Plan")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.lumoGreen)
                    .cornerRadius(8)
                }
                
                HStack(spacing: 8) {
                    Button(action: onAddToGroceryList) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption)
                            
                            Text("Add Ingredients")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button(action: onViewRecipe) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            
                            Text("View Recipe")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingDatePicker) {
            MealPlanDatePickerView(
                recipe: recipe,
                selectedDate: $selectedDate,
                selectedMealType: $selectedMealType,
                onConfirm: {
                    addToMealPlan()
                    showingDatePicker = false
                }
            )
        }
    }
    
    private func addToMealPlan() {
        let meal = Meal(
            date: selectedDate,
            type: selectedMealType,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: recipe.servings
        )
        MealPlanManager.shared.addMeal(meal)
        onAddToMealPlan()
    }
}

// MARK: - Meal Plan Date Picker View
struct MealPlanDatePickerView: View {
    let recipe: Recipe
    @Binding var selectedDate: Date
    @Binding var selectedMealType: MealType
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Recipe Preview
                    VStack(spacing: 12) {
                        Text(recipe.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Add to your meal plan")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Date")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        DatePicker(
                            "Date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                    }
                    
                    // Meal Type Picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meal Type")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                MealTypeSelectionButton(
                                    mealType: mealType,
                                    isSelected: selectedMealType == mealType
                                ) {
                                    selectedMealType = mealType
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Confirm Button
                    Button(action: onConfirm) {
                        Text("Add to Meal Plan")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lumoGreen)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Add to Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Meal Type Selection Button
struct MealTypeSelectionButton: View {
    let mealType: MealType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mealType.color : mealType.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(mealType.emoji)
                        .font(.title3)
                }
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? mealType.color.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Chatbot Meal Response Helper
struct ChatbotMealResponseHelper {
    static func createMealSuggestionMessage(
        recipe: Recipe,
        suggestedDate: Date = Date(),
        suggestedMealType: MealType = .dinner
    ) -> ChatMessage {
        let actionButtons = [
            ChatActionButton(
                title: "Add to Meal Plan",
                action: .addToMealPlan,
                icon: "calendar.badge.plus",
                color: "#00FF88"
            ),
            ChatActionButton(
                title: "Add Ingredients",
                action: .addToList,
                icon: "cart.badge.plus",
                color: "#007AFF"
            ),
            ChatActionButton(
                title: "View Recipe",
                action: .showRecipe,
                icon: "doc.text",
                color: "#8E8E93"
            )
        ]
        
        return ChatMessage(
            content: "Here's a great recipe for you: \(recipe.name). Would you like to add it to your meal plan?",
            isUser: false,
            recipe: recipe,
            actionButtons: actionButtons
        )
    }
} 