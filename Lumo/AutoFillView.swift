//
//  AutoFillView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

// MARK: - Auto Fill View
struct AutoFillView: View {
    let onComplete: ([MealPlan]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: AutoFillStep = .inputs
    @State private var userInputs = AutoFillInputs()
    @State private var generatedMealPlan: [MealPlan] = []
    @State private var showingConfirmation = false
    
    enum AutoFillStep {
        case inputs
        case review
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Progress Indicator
                    progressIndicator
                    
                    // Content based on current step
                    if currentStep == .inputs {
                        inputsView
                    } else {
                        reviewView
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Auto-Fill My Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == .inputs {
                        Button("Generate") {
                            generateMealPlan()
                        }
                        .foregroundColor(.lumoGreen)
                        .disabled(!userInputs.isValid)
                    } else {
                        Button("Apply") {
                            showingConfirmation = true
                        }
                        .foregroundColor(.lumoGreen)
                    }
                }
            }
        }
        .confirmationDialog(
            "Replace Current Plan",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                onComplete(generatedMealPlan)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will replace your current meal plan. Continue?")
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentStep == .inputs ? Color.lumoGreen : Color.gray)
                .frame(width: 12, height: 12)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 2)
            
            Circle()
                .fill(currentStep == .review ? Color.lumoGreen : Color.gray)
                .frame(width: 12, height: 12)
        }
        .padding(.horizontal)
    }
    
    private var inputsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Let's Plan Your Week!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Tell us about your preferences and we'll create a balanced meal plan")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Number of People
                VStack(alignment: .leading, spacing: 12) {
                    Text("Number of People")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Button(action: {
                            if userInputs.numberOfPeople > 1 {
                                userInputs.numberOfPeople -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.lumoGreen)
                                .font(.title2)
                        }
                        .disabled(userInputs.numberOfPeople <= 1)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(userInputs.numberOfPeople)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("people")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            userInputs.numberOfPeople += 1
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
                
                // Meals per Day
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meals per Day")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach([2, 3, 4], id: \.self) { mealCount in
                            MealCountChip(
                                count: mealCount,
                                isSelected: userInputs.mealsPerDay == mealCount,
                                onSelect: {
                                    userInputs.mealsPerDay = mealCount
                                }
                            )
                        }
                    }
                }
                
                // Time Constraints
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time per Meal")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(TimeConstraint.allCases, id: \.self) { constraint in
                            TimeConstraintChip(
                                constraint: constraint,
                                isSelected: userInputs.timeConstraint == constraint,
                                onSelect: {
                                    userInputs.timeConstraint = constraint
                                }
                            )
                        }
                    }
                }
                
                // Budget
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Budget")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(BudgetRange.allCases, id: \.self) { budget in
                            BudgetChip(
                                budget: budget,
                                isSelected: userInputs.budgetRange == budget,
                                onSelect: {
                                    userInputs.budgetRange = budget
                                }
                            )
                        }
                    }
                }
                
                // Dietary Preferences
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dietary Preferences")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(DietaryPreference.allCases, id: \.self) { preference in
                            DietaryChip(
                                preference: preference,
                                isSelected: userInputs.dietaryPreferences.contains(preference),
                                onToggle: { isSelected in
                                    if isSelected {
                                        userInputs.dietaryPreferences.insert(preference)
                                    } else {
                                        userInputs.dietaryPreferences.remove(preference)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Generated Meal Plan")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Review your personalized meal plan for the week")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Weekly Overview
                LazyVStack(spacing: 16) {
                    ForEach(Array(generatedMealPlan.enumerated()), id: \.offset) { index, plan in
                        DayMealPlanCard(
                            dayOffset: index,
                            mealPlan: plan,
                            onRegenerate: {
                                regenerateDay(index)
                            }
                        )
                    }
                }
                
                // Summary
                VStack(spacing: 12) {
                    Text("Plan Summary")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack {
                            Text("\(totalMeals)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.lumoGreen)
                            Text("Total Meals")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("$\(estimatedTotalCost, specifier: "%.0f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.lumoGreen)
                            Text("Estimated Cost")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(averagePrepTime)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.lumoGreen)
                            Text("Avg Prep (min)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var totalMeals: Int {
        generatedMealPlan.reduce(0) { $0 + $1.meals.count }
    }
    
    private var estimatedTotalCost: Double {
        generatedMealPlan.reduce(0) { total, plan in
            total + plan.meals.reduce(0) { mealTotal, meal in
                mealTotal + meal.ingredients.reduce(0) { $0 + $1.price }
            }
        }
    }
    
    private var averagePrepTime: Int {
        let totalTime = generatedMealPlan.reduce(0) { total, plan in
            total + plan.meals.reduce(0) { mealTotal, meal in
                mealTotal + (meal.recipe?.totalTime ?? 30)
            }
        }
        return totalTime / max(totalMeals, 1)
    }
    
    private func generateMealPlan() {
        let generator = SmartMealPlanGenerator()
        generatedMealPlan = generator.generateMealPlan(for: userInputs)
        currentStep = .review
    }
    
    private func regenerateDay(_ dayIndex: Int) {
        let generator = SmartMealPlanGenerator()
        let newDayPlan = generator.generateDayPlan(for: userInputs, dayOffset: dayIndex)
        generatedMealPlan[dayIndex] = newDayPlan
    }
}

// MARK: - Auto Fill Inputs
struct AutoFillInputs {
    var numberOfPeople: Int = 2
    var mealsPerDay: Int = 3
    var timeConstraint: TimeConstraint = .under30
    var budgetRange: BudgetRange = .medium
    var dietaryPreferences: Set<DietaryPreference> = []
    
    var isValid: Bool {
        numberOfPeople > 0 && mealsPerDay > 0
    }
}

// MARK: - Enums
enum TimeConstraint: String, CaseIterable {
    case under15 = "Under 15 min"
    case under30 = "Under 30 min"
    case under45 = "Under 45 min"
    case anyTime = "Any time"
    
    var maxMinutes: Int {
        switch self {
        case .under15: return 15
        case .under30: return 30
        case .under45: return 45
        case .anyTime: return 999
        }
    }
}

enum BudgetRange: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var maxWeeklyBudget: Double {
        switch self {
        case .low: return 50.0
        case .medium: return 100.0
        case .high: return 200.0
        }
    }
}

enum DietaryPreference: String, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    case keto = "Keto"
    case paleo = "Paleo"
}

// MARK: - Chip Views
struct MealCountChip: View {
    let count: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                .cornerRadius(12)
        }
    }
}

struct TimeConstraintChip: View {
    let constraint: TimeConstraint
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(isSelected ? .white : .gray)
                    .font(.title3)
                
                Text(constraint.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct BudgetChip: View {
    let budget: BudgetRange
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(isSelected ? .white : .gray)
                    .font(.title3)
                
                Text(budget.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct DietaryChip: View {
    let preference: DietaryPreference
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            Text(preference.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Day Meal Plan Card
struct DayMealPlanCard: View {
    let dayOffset: Int
    let mealPlan: MealPlan
    let onRegenerate: () -> Void
    
    private var dayName: String {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: Int {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        return Calendar.current.component(.day, from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(dayNumber)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button("Regenerate") {
                    onRegenerate()
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(mealPlan.meals, id: \.id) { meal in
                    HStack {
                        Text(meal.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 60, alignment: .leading)
                        
                        if let recipe = meal.recipe {
                            Text(recipe.name)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        } else if let customMeal = meal.customMeal {
                            Text(customMeal)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let recipe = meal.recipe {
                            Text("\(recipe.totalTime) min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 