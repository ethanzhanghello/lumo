//
//  SpoonacularRecipeView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct SpoonacularRecipeView: View {
    @StateObject private var spoonacularService = SpoonacularService.shared
    @State private var searchText = ""
    @State private var selectedDiet: String?
    @State private var selectedCuisine: String?
    @State private var maxReadyTime: Int?
    @State private var showingFilters = false
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback for recipe selection (used when this view is used as a picker)
    let onRecipeSelected: ((Recipe) -> Void)?
    
    init(onRecipeSelected: ((Recipe) -> Void)? = nil) {
        self.onRecipeSelected = onRecipeSelected
    }
    
    // Filter options
    private let diets = [
        "Gluten Free", "Ketogenic", "Vegetarian", "Lacto-Vegetarian", 
        "Ovo-Vegetarian", "Vegan", "Pescetarian", "Paleo", "Primal", 
        "Low FODMAP", "Whole30"
    ]
    
    private let cuisines = [
        "African", "American", "British", "Cajun", "Caribbean", "Chinese",
        "Eastern European", "European", "French", "German", "Greek", "Indian",
        "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American",
        "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern",
        "Spanish", "Thai", "Vietnamese"
    ]
    
    private let timeOptions = [
        ("15 minutes", 15),
        ("30 minutes", 30),
        ("45 minutes", 45),
        ("60 minutes", 60)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Search and Filter Header
                    VStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search recipes...", text: $searchText)
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    searchRecipes()
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        
                        // Filter Button
                        Button(action: { showingFilters.toggle() }) {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text("Filters")
                                Spacer()
                                if hasActiveFilters {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content
                    if isLoading {
                        Spacer()
                        ProgressView("Searching recipes...")
                            .foregroundColor(.white)
                        Spacer()
                    } else if recipes.isEmpty && !searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No recipes found")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Try adjusting your search or filters")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        // Recipe List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(recipes) { recipe in
                                    SpoonacularRecipeCard(recipe: recipe, onRecipeSelected: onRecipeSelected)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Spoonacular Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if onRecipeSelected != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedDiet: $selectedDiet,
                    selectedCuisine: $selectedCuisine,
                    maxReadyTime: $maxReadyTime,
                    diets: diets,
                    cuisines: cuisines,
                    timeOptions: timeOptions
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(spoonacularService.lastError ?? "An unknown error occurred")
            }
            .onAppear {
                if recipes.isEmpty && searchText.isEmpty {
                    loadRandomRecipes()
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedDiet != nil || selectedCuisine != nil || maxReadyTime != nil
    }
    
    private func searchRecipes() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        Task {
            let results = await spoonacularService.searchRecipes(
                query: searchText,
                diet: selectedDiet,
                cuisine: selectedCuisine,
                maxReadyTime: maxReadyTime
            )
            
            await MainActor.run {
                self.recipes = results
                self.isLoading = false
                
                if let error = spoonacularService.lastError {
                    self.showingError = true
                }
            }
        }
    }
    
    private func loadRandomRecipes() {
        isLoading = true
        Task {
            let results = await spoonacularService.getRandomRecipes(number: 10)
            
            await MainActor.run {
                self.recipes = results
                self.isLoading = false
                
                if let error = spoonacularService.lastError {
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Spoonacular Recipe Card
struct SpoonacularRecipeCard: View {
    let recipe: Recipe
    @State private var showingDetail = false
    let onRecipeSelected: ((Recipe) -> Void)?
    
    init(recipe: Recipe, onRecipeSelected: ((Recipe) -> Void)? = nil) {
        self.recipe = recipe
        self.onRecipeSelected = onRecipeSelected
    }
    
    var body: some View {
        Button(action: { 
            if let onRecipeSelected = onRecipeSelected {
                onRecipeSelected(recipe)
            } else {
                showingDetail = true
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Recipe Image
                if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(12)
                }
                
                // Recipe Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    
                    // Recipe Stats
                    HStack(spacing: 16) {
                        SpoonacularRecipeStat(icon: "clock", value: "\(recipe.totalTime) min", label: "Total Time")
                        SpoonacularRecipeStat(icon: "person.2", value: "\(recipe.servings) servings", label: "Servings")
                        SpoonacularRecipeStat(icon: "star.fill", value: String(format: "%.1f", recipe.rating), label: "Rating")
                    }
                    
                    // Dietary Tags
                    if !recipe.dietaryInfo.dietaryTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipe.dietaryInfo.dietaryTags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            SpoonacularRecipeDetailView(recipe: recipe)
        }
    }
}

// MARK: - Recipe Stat
struct SpoonacularRecipeStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedDiet: String?
    @Binding var selectedCuisine: String?
    @Binding var maxReadyTime: Int?
    let diets: [String]
    let cuisines: [String]
    let timeOptions: [(String, Int)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Diet Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Diet")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(diets, id: \.self) { diet in
                                    FilterChip(
                                        title: diet,
                                        isSelected: selectedDiet == diet
                                    ) {
                                        if selectedDiet == diet {
                                            selectedDiet = nil
                                        } else {
                                            selectedDiet = diet
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Cuisine Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cuisine")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(cuisines, id: \.self) { cuisine in
                                    FilterChip(
                                        title: cuisine,
                                        isSelected: selectedCuisine == cuisine
                                    ) {
                                        if selectedCuisine == cuisine {
                                            selectedCuisine = nil
                                        } else {
                                            selectedCuisine = cuisine
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Time Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maximum Ready Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(timeOptions, id: \.0) { option in
                                    FilterChip(
                                        title: option.0,
                                        isSelected: maxReadyTime == option.1
                                    ) {
                                        if maxReadyTime == option.1 {
                                            maxReadyTime = nil
                                        } else {
                                            maxReadyTime = option.1
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Clear Filters Button
                        Button(action: {
                            selectedDiet = nil
                            selectedCuisine = nil
                            maxReadyTime = nil
                        }) {
                            Text("Clear All Filters")
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recipe Detail View
struct SpoonacularRecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @StateObject private var spoonacularService = SpoonacularService.shared
    @State private var similarRecipes: [Recipe] = []
    @State private var isLoadingSimilar = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Recipe Image
                        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "fork.knife")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(height: 250)
                            .clipped()
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Recipe Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .bold()
                                
                                Text(recipe.description)
                                    .foregroundColor(.gray)
                                
                                // Recipe Stats
                                HStack(spacing: 20) {
                                    SpoonacularRecipeStat(icon: "clock", value: "\(recipe.totalTime) min", label: "Total Time")
                                    SpoonacularRecipeStat(icon: "person.2", value: "\(recipe.servings)", label: "Servings")
                                    SpoonacularRecipeStat(icon: "star.fill", value: String(format: "%.1f", recipe.rating), label: "Rating")
                                }
                            }
                            
                            // Ingredients
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(recipe.ingredients, id: \.id) { ingredient in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.green)
                                        Text("\(ingredient.displayAmount) \(ingredient.name)")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // Instructions
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Instructions")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .foregroundColor(.green)
                                            .font(.headline)
                                        Text(instruction)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // Similar Recipes
                            if !similarRecipes.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Similar Recipes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(similarRecipes.prefix(5)) { similarRecipe in
                                                SimilarRecipeCard(recipe: similarRecipe)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadSimilarRecipes()
            }
        }
    }
    
    private func loadSimilarRecipes() {
        guard let recipeId = Int(recipe.id.replacingOccurrences(of: "SPOON_", with: "")) else { return }
        
        isLoadingSimilar = true
        Task {
            let results = await spoonacularService.getSimilarRecipes(id: recipeId)
            
            await MainActor.run {
                self.similarRecipes = results
                self.isLoadingSimilar = false
            }
        }
    }
}

// MARK: - Similar Recipe Card
struct SimilarRecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 120, height: 80)
                .clipped()
                .cornerRadius(8)
            }
            
            Text(recipe.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .frame(width: 120)
    }
}

#Preview {
    SpoonacularRecipeView()
} 