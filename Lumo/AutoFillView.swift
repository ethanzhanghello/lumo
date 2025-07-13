//
//  AutoFillView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct AutoFillView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var preferences = AutoFillPreferences()
    @State private var showingPreview = false
    @State private var generatedMeals: [Meal] = []
    @State private var weekStartDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Preferences
                        preferencesSection
                        
                        // Generate Button
                        generateButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Auto-Fill Week")
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
        .sheet(isPresented: $showingPreview) {
            AutoFillPreviewView(meals: generatedMeals, weekStart: weekStartDate) {
                applyAutoFill()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Meal Planning")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Let AI create a balanced week of meals based on your preferences and dietary goals.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Preferences")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Dietary Restrictions
            dietaryRestrictionsSection
            
            // Cooking Time
            cookingTimeSection
            
            // Budget
            budgetSection
            
            // Cuisine Preferences
            cuisinePreferencesSection
            
            // Servings
            servingsSection
        }
    }
    
    private var dietaryRestrictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Restrictions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(dietaryOptions, id: \.self) { option in
                    DietaryChip(
                        title: option,
                        isSelected: preferences.dietaryRestrictions.contains(option)
                    ) {
                        if preferences.dietaryRestrictions.contains(option) {
                            preferences.dietaryRestrictions.removeAll { $0 == option }
                        } else {
                            preferences.dietaryRestrictions.append(option)
                        }
                    }
                }
            }
        }
    }
    
    private var cookingTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Max Cooking Time")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Text("\(preferences.maxCookingTime) minutes")
                    .font(.headline)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
                
                Slider(value: Binding(
                    get: { Double(preferences.maxCookingTime) },
                    set: { preferences.maxCookingTime = Int($0) }
                ), in: 15...120, step: 15)
                .accentColor(.lumoGreen)
            }
        }
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget per Meal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Text("$\(String(format: "%.2f", preferences.budgetPerMeal))")
                    .font(.headline)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
                
                Slider(value: $preferences.budgetPerMeal, in: 5...30, step: 1)
                    .accentColor(.lumoGreen)
            }
        }
    }
    
    private var cuisinePreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferred Cuisines")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(cuisineOptions, id: \.self) { cuisine in
                    CuisineChip(
                        title: cuisine,
                        isSelected: preferences.preferredCuisines.contains(cuisine)
                    ) {
                        if preferences.preferredCuisines.contains(cuisine) {
                            preferences.preferredCuisines.removeAll { $0 == cuisine }
                        } else {
                            preferences.preferredCuisines.append(cuisine)
                        }
                    }
                }
            }
        }
    }
    
    private var servingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings per Meal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if preferences.servingsPerMeal > 1 {
                        preferences.servingsPerMeal -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title2)
                }
                .disabled(preferences.servingsPerMeal <= 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(preferences.servingsPerMeal)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("servings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    preferences.servingsPerMeal += 1
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
    
    private var generateButton: some View {
        Button(action: generateMealPlan) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                
                Text("Generate Meal Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helper Functions
    private func generateMealPlan() {
        // Calculate week start (Monday)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday == 1 ? 0 : weekday - 2 // Monday is 2, so subtract 1
        weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        
        generatedMeals = mealManager.generateAutoFillPlan(for: weekStartDate, preferences: preferences)
        showingPreview = true
    }
    
    private func applyAutoFill() {
        print("Applying \(generatedMeals.count) meals to meal plan")
        for meal in generatedMeals {
            print("Adding meal: \(meal.recipeName) for \(meal.date.formatted(date: .abbreviated, time: .omitted))")
            mealManager.addMeal(meal)
        }
        
        // Force UI update
        DispatchQueue.main.async {
            mealManager.objectWillChange.send()
        }
        
        print("Auto-fill applied successfully. Total meals in plan: \(mealManager.mealPlan.values.flatMap { $0 }.count)")
        dismiss()
    }
    
    // MARK: - Data
    private let dietaryOptions = [
        "Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free",
        "Low-Carb", "Keto", "Paleo", "Nut-Free"
    ]
    
    private let cuisineOptions = [
        "Italian", "Mexican", "Asian", "Mediterranean",
        "American", "Indian", "French", "Thai"
    ]
}

// MARK: - Dietary Chip
struct DietaryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
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

// MARK: - Cuisine Chip
struct CuisineChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Auto-Fill Preview View
struct AutoFillPreviewView: View {
    let meals: [Meal]
    let weekStart: Date
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Generated Meal Plan")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(meals.count) meals for the week")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Weekly Overview
                        weeklyOverview
                        
                        // Meal Details
                        mealDetails
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
    }
    
    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(0..<7) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) ?? Date()
                    let dayMeals = meals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    
                    VStack(spacing: 4) {
                        Text(dayOfWeek(for: date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if !dayMeals.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(dayMeals.prefix(3), id: \.id) { meal in
                                    Text(meal.type.emoji)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 60)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var mealDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Details")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(meals.sorted { $0.date < $1.date }, id: \.id) { meal in
                    PreviewMealCard(meal: meal)
                }
            }
        }
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Preview Meal Card
struct PreviewMealCard: View {
    let meal: Meal
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal Type Icon
            ZStack {
                Circle()
                    .fill(meal.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(meal.type.emoji)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(meal.type.rawValue) • \(meal.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let recipe = meal.recipe {
                    Text("\(recipe.totalTime) min • \(meal.servings) servings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 