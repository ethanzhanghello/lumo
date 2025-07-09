//
//  AddMealView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    
    let selectedDate: Date
    let selectedMealType: MealType
    
    @State private var recipeName = ""
    @State private var ingredients: [String] = []
    @State private var servings = 2
    @State private var notes = ""
    @State private var newIngredient = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Recipe Details") {
                    TextField("Recipe Name", text: $recipeName)
                    
                    Picker("Meal Type", selection: .constant(selectedMealType)) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .disabled(true)
                    
                    Stepper("Servings: \(servings)", value: $servings, in: 1...12)
                }
                
                Section("Ingredients") {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            TextField("Ingredient", text: $ingredients[index])
                            
                            Button("Remove") {
                                ingredients.remove(at: index)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .onDelete(perform: deleteIngredients)
                    
                    HStack {
                        TextField("Add ingredient", text: $newIngredient)
                        
                        Button("Add") {
                            if !newIngredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                ingredients.append(newIngredient.trimmingCharacters(in: .whitespacesAndNewlines))
                                newIngredient = ""
                            }
                        }
                        .disabled(newIngredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredients.isEmpty &&
        servings > 0
    }
    
    private func deleteIngredients(offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func saveMeal() {
        let meal = Meal(
            date: selectedDate,
            type: selectedMealType,
            recipeName: recipeName.trimmingCharacters(in: .whitespacesAndNewlines),
            ingredients: ingredients,
            servings: servings,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        mealManager.addMeal(meal)
        dismiss()
    }
}

#Preview {
    AddMealView(selectedDate: Date(), selectedMealType: .dinner)
} 