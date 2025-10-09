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
    @State private var selectedDays: Set<Int> = Set(0..<7) // Default: all days selected
    @State private var isGenerating = false
    @State private var replaceExistingMeals = false // New option
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Day Selection
                            daySelectionSection
                            
                            // Preferences
                            preferencesSection
                            
                            // Generate Button
                            generateButton
                            
                            // Bottom spacing for safe scrolling
                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Auto-Fill Week")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
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
    

    
    // MARK: - Day Selection Section
    private var daySelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Days to Auto-Fill")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Choose which days you want to generate meals for")
                .font(.caption)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStartDate) ?? Date()
                    let dayName = dayFormatter.string(from: date)
                    let dateString = dayDateFormatter.string(from: date)
                    let isSelected = selectedDays.contains(dayOffset)
                    let mealCount = mealManager.meals(for: date).count
                    
                    Button(action: {
                        if isSelected {
                            selectedDays.remove(dayOffset)
                        } else {
                            selectedDays.insert(dayOffset)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(dayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(isSelected ? .black : .gray)
                            
                            Text(dateString)
                                .font(.caption2)
                                .foregroundColor(isSelected ? .black : .gray)
                            
                            if mealCount > 0 {
                                Text("\(mealCount) meals")
                                    .font(.caption2)
                                    .foregroundColor(isSelected ? .orange : .gray)
                                    .fontWeight(.medium)
                            } else {
                                Text("empty")
                                    .font(.caption2)
                                    .foregroundColor(isSelected ? .black : .gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            
            HStack {
                Button("Select All") {
                    selectedDays = Set(0..<7)
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
                
                Spacer()
                
                Button("Clear All") {
                    selectedDays.removeAll()
                }
                .foregroundColor(.gray)
                .font(.caption)
                
                Spacer()
                
                Text("\(selectedDays.count) days selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Replace Existing Meals Toggle
            HStack {
                Toggle("Replace existing meals", isOn: $replaceExistingMeals)
                    .foregroundColor(.white)
            }
            .padding(.top, 8)
            
            if replaceExistingMeals {
                Text("⚠️ This will replace all existing meals on selected days")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("ℹ️ Only empty meal slots will be filled")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var dayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
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
                Text("$\(preferences.budgetPerMeal, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
                
                Slider(value: $preferences.budgetPerMeal, in: 5...50, step: 2.5)
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
                ForEach(cuisineOptions, id: \.self) { option in
                    CuisineChip(
                        title: option,
                        isSelected: preferences.preferredCuisines.contains(option)
                    ) {
                        if preferences.preferredCuisines.contains(option) {
                            preferences.preferredCuisines.removeAll { $0 == option }
                        } else {
                            preferences.preferredCuisines.append(option)
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
                Text("\(preferences.servingsPerMeal) servings")
                    .font(.headline)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
                
                Stepper("", value: $preferences.servingsPerMeal, in: 1...8)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: generateMealPlan) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                }
                
                Text(isGenerating ? "Generating..." : "Generate Meal Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                selectedDays.isEmpty ? 
                    AnyShapeStyle(Color.gray) : 
                    AnyShapeStyle(LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .cornerRadius(16)
        }
        .disabled(selectedDays.isEmpty || isGenerating)
    }
    
    // MARK: - Helper Functions
    private func generateMealPlan() {
        print("🔵 Starting meal generation...")
        print("🔵 Selected days: \(selectedDays)")
        print("🔵 Replace existing meals: \(replaceExistingMeals)")
        
        isGenerating = true
        
        // Calculate week start (Monday)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday == 1 ? 0 : weekday - 2 // Monday is 2, so subtract 1
        weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        
        print("🔵 Week start date: \(weekStartDate)")
        print("🔵 Preferences: \(preferences)")
        
        // Generate meals only for selected days
        let allGeneratedMeals = mealManager.generateAutoFillPlan(for: weekStartDate, preferences: preferences, replaceExisting: replaceExistingMeals)
        
        print("🔵 All generated meals count: \(allGeneratedMeals.count)")
        for meal in allGeneratedMeals {
            print("🔵 Generated meal: \(meal.recipeName) for \(meal.date.formatted(date: .abbreviated, time: .omitted))")
        }
        
        // Filter to only include selected days
        generatedMeals = allGeneratedMeals.filter { meal in
            let dayOffset = calendar.dateComponents([.day], from: weekStartDate, to: meal.date).day ?? 0
            let isSelected = selectedDays.contains(dayOffset)
            print("🔵 Meal \(meal.recipeName) day offset: \(dayOffset), selected: \(isSelected)")
            return isSelected
        }
        
        print("🔵 Filtered meals count: \(generatedMeals.count)")
        print("🔵 Generated \(generatedMeals.count) meals for \(selectedDays.count) selected days")
        
        isGenerating = false
        
        if !generatedMeals.isEmpty {
            print("🔵 Showing preview with \(generatedMeals.count) meals")
            showingPreview = true
        } else {
            print("🔴 No meals generated - not showing preview")
        }
    }
    
    private func applyAutoFill() {
        print("🔵 Applying \(generatedMeals.count) meals to meal plan")
        print("🔵 Replace existing meals: \(replaceExistingMeals)")
        
        // If replacing existing meals, remove them first
        if replaceExistingMeals {
            for dayOffset in selectedDays {
                guard let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                let existingMeals = mealManager.meals(for: dayDate)
                print("🔵 Removing \(existingMeals.count) existing meals from \(dayDate.formatted(date: .abbreviated, time: .omitted))")
                for meal in existingMeals {
                    mealManager.removeMeal(meal)
                }
            }
        }
        
        // Add new generated meals
        for meal in generatedMeals {
            print("🔵 Adding meal: \(meal.recipeName) for \(meal.date.formatted(date: .abbreviated, time: .omitted))")
            mealManager.addMeal(meal)
        }
        
        // Force UI update
        DispatchQueue.main.async {
            mealManager.objectWillChange.send()
        }
        
        print("🔵 Auto-fill applied successfully. Total meals in plan: \(mealManager.mealPlan.values.flatMap { $0 }.count)")
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Preview (\(meals.count) meals)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
                .padding()
                .background(Color.black)
                
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