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



// MARK: - Meal struct (top-level for easy access)
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

struct MealPlan: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var meals: [Meal]
    
    init(date: Date, meals: [Meal] = []) {
        self.date = date
        self.meals = meals
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
        
        // Add sample meals if no meals exist
        if mealPlan.isEmpty {
            addSampleMeals()
        }
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
    func generateAutoFillPlan(for weekStart: Date, preferences: AutoFillPreferences, replaceExisting: Bool = false) -> [Meal] {
        print("🟡 generateAutoFillPlan called (replaceExisting: \(replaceExisting))")
        var generatedMeals: [Meal] = []
        let availableRecipes = RecipeDatabase.recipes
        
        print("🟡 Available recipes count: \(availableRecipes.count)")
        if availableRecipes.isEmpty {
            print("🔴 No recipes available in RecipeDatabase!")
            return generatedMeals
        }
        
        for (index, recipe) in availableRecipes.prefix(3).enumerated() {
            print("🟡 Sample recipe \(index): \(recipe.name)")
        }
        
        for dayOffset in 0..<7 {
            guard let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            print("🟡 Processing day \(dayOffset): \(dayDate.formatted(date: .abbreviated, time: .omitted))")
            
            for mealType in MealType.allCases {
                let hasExistingMeal = hasMeal(for: dayDate, type: mealType)
                print("🟡 \(mealType.rawValue) on \(dayDate.formatted(date: .abbreviated, time: .omitted)): existing meal = \(hasExistingMeal)")
                
                // Generate meal if no existing meal OR if replacing existing meals
                if !hasExistingMeal || replaceExisting {
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
                        print("🟢 Generated meal: \(recipe.name) for \(mealType.rawValue) on \(dayDate.formatted(date: .abbreviated, time: .omitted))")
                    } else {
                        print("🔴 No suitable recipe found for \(mealType.rawValue) on \(dayDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                } else {
                    print("🟡 Skipping \(mealType.rawValue) on \(dayDate.formatted(date: .abbreviated, time: .omitted)) - existing meal and not replacing")
                }
            }
        }
        
        print("🟡 Total generated meals: \(generatedMeals.count)")
        return generatedMeals
    }
    
    private func findSuitableRecipe(for mealType: MealType, preferences: AutoFillPreferences, availableRecipes: [Recipe]) -> Recipe? {
        print("🟠 Finding recipe for \(mealType.rawValue) with \(availableRecipes.count) available recipes")
        
        var filteredRecipes = availableRecipes
        print("🟠 Starting with \(filteredRecipes.count) recipes")
        
        // Filter by cooking time
        filteredRecipes = filteredRecipes.filter { recipe in
            let totalTime = recipe.prepTime + recipe.cookTime
            let meetsTimeRequirement = totalTime <= preferences.maxCookingTime
            if !meetsTimeRequirement {
                print("🟠 Recipe \(recipe.name): total time \(totalTime) > \(preferences.maxCookingTime) - FILTERED OUT")
            }
            return meetsTimeRequirement
        }
        print("🟠 After time filter: \(filteredRecipes.count) recipes remain")
        
        // Filter by budget (if budget is reasonable)
        if preferences.budgetPerMeal > 5 {
            filteredRecipes = filteredRecipes.filter { recipe in
                let meetsBudget = recipe.estimatedCost <= preferences.budgetPerMeal
                if !meetsBudget {
                    print("🟠 Recipe \(recipe.name): cost \(recipe.estimatedCost) > \(preferences.budgetPerMeal) - FILTERED OUT")
                }
                return meetsBudget
            }
            print("🟠 After budget filter: \(filteredRecipes.count) recipes remain")
        }
        
        // Filter by dietary restrictions (only if specified)
        if !preferences.dietaryRestrictions.isEmpty {
            filteredRecipes = filteredRecipes.filter { recipe in
                let recipeTags = recipe.dietaryInfo.dietaryTags
                let hasMatchingRestriction = preferences.dietaryRestrictions.contains { restriction in
                    recipeTags.contains { $0.lowercased().contains(restriction.lowercased()) }
                }
                if !hasMatchingRestriction {
                    print("🟠 Recipe \(recipe.name): no dietary match - FILTERED OUT")
                }
                return hasMatchingRestriction
            }
            print("🟠 After dietary filter: \(filteredRecipes.count) recipes remain")
        }
        
        // Filter by cuisine preference (only if specified)
        if !preferences.preferredCuisines.isEmpty {
            filteredRecipes = filteredRecipes.filter { recipe in
                let hasMatchingCuisine = preferences.preferredCuisines.contains { cuisine in
                    recipe.cuisine.lowercased().contains(cuisine.lowercased())
                }
                if !hasMatchingCuisine {
                    print("🟠 Recipe \(recipe.name): no cuisine match - FILTERED OUT")
                }
                return hasMatchingCuisine
            }
            print("🟠 After cuisine filter: \(filteredRecipes.count) recipes remain")
        }
        
        print("🟠 Final filtered recipes count: \(filteredRecipes.count)")
        
        // Return a random suitable recipe
        let selectedRecipe = filteredRecipes.randomElement()
        if let recipe = selectedRecipe {
            print("🟢 Selected recipe: \(recipe.name) for \(mealType.rawValue)")
        } else {
            print("🔴 No suitable recipe found for \(mealType.rawValue)")
        }
        
        return selectedRecipe
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
                totalNutrition.calories += Int(Double(recipe.nutritionInfo.calories ?? 0) * scaleFactor)
                totalNutrition.protein += (recipe.nutritionInfo.protein ?? 0.0) * scaleFactor
                totalNutrition.carbs += (recipe.nutritionInfo.carbs ?? 0.0) * scaleFactor
                totalNutrition.fat += (recipe.nutritionInfo.fat ?? 0.0) * scaleFactor
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
    private func addSampleMeals() {
        let today = Date()
        let calendar = Calendar.current
        
        // Add sample meals for today and tomorrow
        for dayOffset in 0..<2 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Breakfast
            let breakfast = Meal(
                date: date,
                type: .breakfast,
                recipeName: "Avocado Toast with Eggs",
                ingredients: ["Bread", "Avocado", "Eggs", "Salt", "Pepper"],
                servings: 2
            )
            addMeal(breakfast)
            
            // Lunch
            let lunch = Meal(
                date: date,
                type: .lunch,
                recipeName: "Chicken Caesar Salad",
                ingredients: ["Chicken Breast", "Lettuce", "Parmesan", "Croutons", "Caesar Dressing"],
                servings: 1
            )
            addMeal(lunch)
            
            // Dinner
            let dinner = Meal(
                date: date,
                type: .dinner,
                recipeName: "Grilled Salmon with Vegetables",
                ingredients: ["Salmon", "Broccoli", "Carrots", "Olive Oil", "Lemon"],
                servings: 2
            )
            addMeal(dinner)
        }
        
        print("Added sample meals to meal plan")
    }
    
    @MainActor
    static func sampleMealPlans() -> [MealPlan] {
        let today = Date()
        let calendar = Calendar.current
        
        var samplePlans: [MealPlan] = []
        
        // Create sample meal plans for the next 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let meals: [Meal] = [
                Meal(
                    date: date,
                    type: MealType.breakfast,
                    recipeName: RecipeDatabase.recipes.first?.name ?? "Healthy Breakfast Bowl",
                    ingredients: ["Eggs", "Avocado", "Whole Grain Toast"],
                    recipe: RecipeDatabase.recipes.first,
                    customMeal: "Healthy Breakfast Bowl"
                ),
                Meal(
                    date: date,
                    type: MealType.lunch,
                    recipeName: "Fresh Salad with Protein",
                    ingredients: ["Mixed Greens", "Chicken Breast", "Cherry Tomatoes"],
                    recipe: RecipeDatabase.recipes.first(where: { $0.category == .salad }),
                    customMeal: "Fresh Salad with Protein"
                ),
                Meal(
                    date: date,
                    type: MealType.dinner,
                    recipeName: "Balanced Dinner Plate", 
                    ingredients: ["Salmon Fillet", "Quinoa", "Steamed Broccoli"],
                    recipe: RecipeDatabase.recipes.first(where: { $0.category == .dinner }),
                    customMeal: "Balanced Dinner Plate"
                )
            ]
            
            let mealPlan = MealPlan(
                date: date,
                meals: meals
            )
            
            samplePlans.append(mealPlan)
        }
        
        return samplePlans
    }
}

extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
} 