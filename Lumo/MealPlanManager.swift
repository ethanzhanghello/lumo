//
//  MealPlanManager.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Core Data Structures
enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        }
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🍳"
        case .lunch: return "🥪"
        case .dinner: return "🍝"
        case .snack: return "🍎"
        }
    }
}

struct Meal: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var type: MealType
    var recipeName: String
    var ingredients: [String]
    var recipe: Recipe?
    var customMeal: String?
    var servings: Int
    var notes: String?
    var isCompleted: Bool
    
    init(date: Date, type: MealType, recipeName: String, ingredients: [String], recipe: Recipe? = nil, customMeal: String? = nil, servings: Int = 1, notes: String? = nil, isCompleted: Bool = false) {
        self.date = date
        self.type = type
        self.recipeName = recipeName
        self.ingredients = ingredients
        self.recipe = recipe
        self.customMeal = customMeal
        self.servings = servings
        self.notes = notes
        self.isCompleted = isCompleted
    }
    
    static func == (lhs: Meal, rhs: Meal) -> Bool {
        lhs.id == rhs.id
    }
}

struct NutritionData: Codable {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Int?
    
    init(calories: Int = 0, protein: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double? = nil, sugar: Double? = nil, sodium: Int? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
}

struct AutoFillPreferences: Codable {
    var dietaryRestrictions: [String]
    var maxCookingTime: Int // minutes
    var budgetPerMeal: Double
    var preferredCuisines: [String]
    var servingsPerMeal: Int
    
    init(dietaryRestrictions: [String] = [], maxCookingTime: Int = 60, budgetPerMeal: Double = 15.0, preferredCuisines: [String] = [], servingsPerMeal: Int = 2) {
        self.dietaryRestrictions = dietaryRestrictions
        self.maxCookingTime = maxCookingTime
        self.budgetPerMeal = budgetPerMeal
        self.preferredCuisines = preferredCuisines
        self.servingsPerMeal = servingsPerMeal
    }
}

// MARK: - Meal Plan Manager
@MainActor
class MealPlanManager: ObservableObject {
    static let shared = MealPlanManager()
    
    @Published var mealPlan: [Date: [Meal]] = [:]
    @Published var selectedDate = Date()
    @Published var autoFillPreferences = AutoFillPreferences()
    @Published var nutritionGoals = NutritionData(calories: 2000, protein: 150, carbs: 250, fat: 65)
    
    private let userDefaultsKey = "mealPlanData"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFromUserDefaults()
        setupObservers()
    }
    
    // MARK: - Core Functions
    func addMeal(_ meal: Meal) {
        let cleanDate = Calendar.current.startOfDay(for: meal.date)
        if mealPlan[cleanDate] != nil {
            mealPlan[cleanDate]?.append(meal)
        } else {
            mealPlan[cleanDate] = [meal]
        }
        saveToUserDefaults()
    }
    
    func removeMeal(_ meal: Meal) {
        let cleanDate = Calendar.current.startOfDay(for: meal.date)
        mealPlan[cleanDate]?.removeAll { $0.id == meal.id }
        if mealPlan[cleanDate]?.isEmpty == true {
            mealPlan.removeValue(forKey: cleanDate)
        }
        saveToUserDefaults()
    }
    
    func updateMeal(_ meal: Meal) {
        removeMeal(meal)
        addMeal(meal)
    }
    
    func meals(for date: Date) -> [Meal] {
        let cleanDate = Calendar.current.startOfDay(for: date)
        return mealPlan[cleanDate] ?? []
    }
    
    func mealsForWeek(starting date: Date) -> [Meal] {
        var weekMeals: [Meal] = []
        for dayOffset in 0..<7 {
            if let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: date) {
                weekMeals.append(contentsOf: meals(for: dayDate))
            }
        }
        return weekMeals
    }
    
    func mealCount(for date: Date) -> Int {
        return meals(for: date).count
    }
    
    func hasMeal(for date: Date, type: MealType) -> Bool {
        return meals(for: date).contains { $0.type == type }
    }
    
    // MARK: - Auto-Fill Functions
    func generateAutoFillPlan(for weekStart: Date, preferences: AutoFillPreferences) -> [Meal] {
        var generatedMeals: [Meal] = []
        let availableRecipes = RecipeDatabase.recipes
        
        for dayOffset in 0..<7 {
            guard let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            for mealType in MealType.allCases {
                if !hasMeal(for: dayDate, type: mealType) {
                    if let recipe = findSuitableRecipe(for: mealType, preferences: preferences, availableRecipes: availableRecipes) {
                        let meal = Meal(
                            date: dayDate,
                            type: mealType,
                            recipeName: recipe.name,
                            ingredients: recipe.ingredients.map { $0.name },
                            recipe: recipe,
                            servings: preferences.servingsPerMeal
                        )
                        generatedMeals.append(meal)
                    }
                }
            }
        }
        
        return generatedMeals
    }
    
    private func findSuitableRecipe(for mealType: MealType, preferences: AutoFillPreferences, availableRecipes: [Recipe]) -> Recipe? {
        let filteredRecipes = availableRecipes.filter { recipe in
            // Filter by cooking time
            guard recipe.totalTime <= preferences.maxCookingTime else { return false }
            
            // Filter by budget
            guard recipe.estimatedCost <= preferences.budgetPerMeal else { return false }
            
            // Filter by dietary restrictions
            if !preferences.dietaryRestrictions.isEmpty {
                let recipeTags = recipe.dietaryInfo.dietaryTags
                let hasMatchingRestriction = preferences.dietaryRestrictions.contains { restriction in
                    recipeTags.contains { $0.lowercased().contains(restriction.lowercased()) }
                }
                guard hasMatchingRestriction else { return false }
            }
            
            // Filter by cuisine preference
            if !preferences.preferredCuisines.isEmpty {
                let hasPreferredCuisine = preferences.preferredCuisines.contains { cuisine in
                    recipe.cuisine.lowercased().contains(cuisine.lowercased())
                }
                guard hasPreferredCuisine else { return false }
            }
            
            return true
        }
        
        return filteredRecipes.randomElement()
    }
    
    // MARK: - Nutrition Analysis
    func calculateNutritionForWeek(starting date: Date) -> [Date: NutritionData] {
        var weeklyNutrition: [Date: NutritionData] = [:]
        
        for dayOffset in 0..<7 {
            guard let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: date) else { continue }
            let dayMeals = meals(for: dayDate)
            weeklyNutrition[dayDate] = calculateNutritionForMeals(dayMeals)
        }
        
        return weeklyNutrition
    }
    
    private func calculateNutritionForMeals(_ meals: [Meal]) -> NutritionData {
        var totalNutrition = NutritionData()
        
        for meal in meals {
            if let recipe = meal.recipe {
                let scaleFactor = Double(meal.servings) / Double(recipe.servings)
                totalNutrition.calories += Int(Double(recipe.nutritionInfo.calories) * scaleFactor)
                totalNutrition.protein += recipe.nutritionInfo.protein * scaleFactor
                totalNutrition.carbs += recipe.nutritionInfo.carbs * scaleFactor
                totalNutrition.fat += recipe.nutritionInfo.fat * scaleFactor
                if let fiber = recipe.nutritionInfo.fiber {
                    totalNutrition.fiber = (totalNutrition.fiber ?? 0) + fiber * scaleFactor
                }
                if let sugar = recipe.nutritionInfo.sugar {
                    totalNutrition.sugar = (totalNutrition.sugar ?? 0) + sugar * scaleFactor
                }
                if let sodium = recipe.nutritionInfo.sodium {
                    totalNutrition.sodium = (totalNutrition.sodium ?? 0) + Int(Double(sodium) * scaleFactor)
                }
            }
        }
        
        return totalNutrition
    }
    
    // MARK: - Grocery List Generation
    func generateGroceryList(for weekStart: Date) -> [String: [String]] {
        let weekMeals = mealsForWeek(starting: weekStart)
        var allIngredients: [String] = []
        
        for meal in weekMeals {
            allIngredients.append(contentsOf: meal.ingredients)
        }
        
        // Deduplicate ingredients
        let uniqueIngredients = Array(Set(allIngredients))
        
        // Group by category (simplified - in real app would use ingredient database)
        var categorizedIngredients: [String: [String]] = [:]
        
        for ingredient in uniqueIngredients {
            let category = categorizeIngredient(ingredient)
            if categorizedIngredients[category] != nil {
                categorizedIngredients[category]?.append(ingredient)
            } else {
                categorizedIngredients[category] = [ingredient]
            }
        }
        
        return categorizedIngredients
    }
    
    private func categorizeIngredient(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        
        if lowercased.contains("milk") || lowercased.contains("cheese") || lowercased.contains("yogurt") || lowercased.contains("cream") {
            return "Dairy"
        } else if lowercased.contains("apple") || lowercased.contains("banana") || lowercased.contains("tomato") || lowercased.contains("lettuce") || lowercased.contains("carrot") {
            return "Produce"
        } else if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("pork") || lowercased.contains("fish") {
            return "Meat"
        } else if lowercased.contains("bread") || lowercased.contains("pasta") || lowercased.contains("rice") {
            return "Grains"
        } else if lowercased.contains("oil") || lowercased.contains("butter") || lowercased.contains("sauce") {
            return "Pantry"
        } else {
            return "Other"
        }
    }
    
    // MARK: - Persistence
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(mealPlan) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Date: [Meal]].self, from: data) {
            mealPlan = decoded
        }
    }
    
    private func setupObservers() {
        $mealPlan
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sample Data
    @MainActor
    static func sampleMealPlans() -> [MealPlan] {
        let today = Date()
        let calendar = Calendar.current
        
        var samplePlans: [MealPlan] = []
        
        // Create sample meal plans for the next 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let meals: [MealPlan.Meal] = [
                MealPlan.Meal(
                    type: .breakfast,
                    recipe: RecipeDatabase.recipes.first,
                    customMeal: "Healthy Breakfast Bowl",
                    ingredients: [
                        GroceryItem(name: "Eggs", description: "Fresh eggs", price: 2.99, category: "Dairy", aisle: 5, brand: ""),
                        GroceryItem(name: "Avocado", description: "Ripe avocado", price: 1.99, category: "Produce", aisle: 1, brand: ""),
                        GroceryItem(name: "Whole Grain Toast", description: "Healthy bread", price: 3.49, category: "Bakery", aisle: 3, brand: "")
                    ]
                ),
                MealPlan.Meal(
                    type: .lunch,
                    recipe: RecipeDatabase.recipes.first(where: { $0.category == .salad }),
                    customMeal: "Fresh Salad with Protein",
                    ingredients: [
                        GroceryItem(name: "Mixed Greens", description: "Fresh salad greens", price: 2.99, category: "Produce", aisle: 1, brand: ""),
                        GroceryItem(name: "Chicken Breast", description: "Lean protein", price: 8.97, category: "Meat", aisle: 4, brand: ""),
                        GroceryItem(name: "Cherry Tomatoes", description: "Fresh tomatoes", price: 3.99, category: "Produce", aisle: 1, brand: "")
                    ]
                ),
                MealPlan.Meal(
                    type: .dinner,
                    recipe: RecipeDatabase.recipes.first(where: { $0.category == .dinner }),
                    customMeal: "Balanced Dinner Plate",
                    ingredients: [
                        GroceryItem(name: "Salmon Fillet", description: "Fresh fish", price: 12.99, category: "Seafood", aisle: 4, brand: ""),
                        GroceryItem(name: "Brown Rice", description: "Whole grain", price: 2.99, category: "Pantry", aisle: 3, brand: ""),
                        GroceryItem(name: "Broccoli", description: "Fresh vegetables", price: 2.99, category: "Produce", aisle: 1, brand: "")
                    ]
                )
            ]
            
            let mealPlan = MealPlan(
                date: date,
                meals: meals,
                notes: "Sample meal plan for \(date.formatted(date: .abbreviated, time: .omitted))"
            )
            
            samplePlans.append(mealPlan)
        }
        
        return samplePlans
    }
} 