//
//  AddMealView.swift
//  Lumo
//
//  Created by Ethan on 7/11/25.
//

import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    
    let selectedDate: Date
    let selectedMealType: MealType
    
    @State private var recipeName = ""
    @State private var ingredients: [String] = []
    @State private var newIngredient = ""
    @State private var servings = 1
    @State private var notes = ""
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Recipe Selection
                        recipeSelectionSection
                        
                        // Custom Meal Details
                        customMealSection
                        
                        // Ingredients
                        ingredientsSection
                        
                        // Servings
                        servingsSection
                        
                        // Notes
                        notesSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .foregroundColor(.lumoGreen)
                    .disabled(recipeName.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingRecipePicker) {
            RecipePickerView(selectedRecipe: $selectedRecipe)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add \(selectedMealType.rawValue)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Add a meal for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Recipe Selection Section
    private var recipeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Button(action: {
                showingRecipePicker = true
            }) {
                HStack {
                    if let recipe = selectedRecipe {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("\(recipe.ingredients.count) ingredients • \(recipe.prepTime + recipe.cookTime) min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Select from Recipe Database")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("OR")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Custom Meal Section
    private var customMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Meal Name")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("Enter meal name", text: $recipeName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Add ingredient field
            HStack {
                TextField("Add ingredient", text: $newIngredient)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(.white)
                
                Button("Add") {
                    if !newIngredient.isEmpty {
                        ingredients.append(newIngredient)
                        newIngredient = ""
                    }
                }
                .foregroundColor(.lumoGreen)
                .disabled(newIngredient.isEmpty)
            }
            
            // Ingredients list
            if !ingredients.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            Text("• \(ingredients[index])")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                ingredients.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Servings Section
    private var servingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if servings > 1 {
                        servings -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title2)
                }
                .disabled(servings <= 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(servings)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("servings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    servings += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("Add notes...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.white)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Helper Functions
    private func saveMeal() {
        let mealName = selectedRecipe?.name ?? recipeName
        let mealIngredients = selectedRecipe?.ingredients.map { $0.name } ?? ingredients
        
        let meal = Meal(
            date: selectedDate,
            type: selectedMealType,
            recipeName: mealName,
            ingredients: mealIngredients,
            recipe: selectedRecipe,
            customMeal: selectedRecipe == nil ? recipeName : nil,
            servings: servings,
            notes: notes.isEmpty ? nil : notes
        )
        
        mealManager.addMeal(meal)
        print("Added meal: \(mealName) for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
        
        dismiss()
    }
}

// MARK: - Recipe Picker View
struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedRecipe: Recipe?
    @State private var searchText = ""
    
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return RecipeDatabase.recipes
        } else {
            return RecipeDatabase.recipes.filter { recipe in
                recipe.name.localizedCaseInsensitiveContains(searchText) ||
                recipe.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Search bar
                    TextField("Search recipes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    // Recipe list
                    List(filteredRecipes, id: \.id) { recipe in
                        Button(action: {
                            selectedRecipe = recipe
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(recipe.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text("\(recipe.ingredients.count) ingredients")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text("\(recipe.prepTime + recipe.cookTime) min")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Recipe")
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