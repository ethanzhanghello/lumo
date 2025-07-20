//
//  SmartMealPlanGenerator.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import Foundation

// MARK: - AutoFill Input Types
struct AutoFillInputs {
    let numberOfPeople: Int
    let mealsPerDay: Int
    let timeConstraint: TimeConstraint
    let budgetRange: BudgetRange
    let dietaryPreferences: Set<DietaryPreference>
    let cuisinePreferences: Set<CuisineType>
    let skillLevel: CookingSkillLevel
    let equipmentAvailable: Set<CookingEquipment>
    let allergies: Set<Allergen>
    let seasonalPreferences: Bool
    let leftoversPreference: Bool
}

struct TimeConstraint {
    let maxMinutes: Int
    let preferredTimeRange: ClosedRange<Int>?
}

struct BudgetRange {
    let maxWeeklyBudget: Double
    let preferredRange: ClosedRange<Double>?
}

enum DietaryPreference: String, CaseIterable {
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case lowCarb = "low_carb"
    case highProtein = "high_protein"
    case keto = "keto"
    case paleo = "paleo"
}

enum CuisineType: String, CaseIterable {
    case italian = "italian"
    case mexican = "mexican"
    case asian = "asian"
    case mediterranean = "mediterranean"
    case american = "american"
    case indian = "indian"
    case french = "french"
    case thai = "thai"
}

enum CookingSkillLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}

enum CookingEquipment: String, CaseIterable {
    case oven = "oven"
    case stovetop = "stovetop"
    case microwave = "microwave"
    case slowCooker = "slow_cooker"
    case airFryer = "air_fryer"
    case blender = "blender"
    case foodProcessor = "food_processor"
}

enum Allergen: String, CaseIterable {
    case peanuts = "peanuts"
    case treeNuts = "tree_nuts"
    case milk = "milk"
    case eggs = "eggs"
    case soy = "soy"
    case wheat = "wheat"
    case fish = "fish"
    case shellfish = "shellfish"
}

// MARK: - Meal Plan Types
// Using existing MealPlan from AppState.swift

class SmartMealPlanGenerator {
    
    // MARK: - Main Generation Method
    func generateMealPlan(for inputs: AutoFillInputs) -> [MealPlan] {
        var mealPlans: [MealPlan] = []
        
        // Generate meal plans for the next 7 days
        for dayOffset in 0..<7 {
            let mealPlan = generateDayPlan(for: inputs, dayOffset: dayOffset)
            mealPlans.append(mealPlan)
        }
        
        return mealPlans
    }
    
    func generateDayPlan(for inputs: AutoFillInputs, dayOffset: Int) -> MealPlan {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let meals = generateMealsForDay(inputs: inputs, dayOffset: dayOffset)
        
        return MealPlan(
            date: date,
            meals: meals
        )
    }
    
    // MARK: - Meal Generation Logic
    private func generateMealsForDay(inputs: AutoFillInputs, dayOffset: Int) -> [Meal] {
        var meals: [Meal] = []
        let availableRecipes = filterRecipesForConstraints(inputs: inputs)
        
        // Determine meal types based on meals per day
        let mealTypes = getMealTypesForDay(mealsPerDay: inputs.mealsPerDay, dayOffset: dayOffset)
        
        for mealType in mealTypes {
            if let meal = generateMeal(
                type: mealType,
                availableRecipes: availableRecipes,
                inputs: inputs,
                existingMeals: meals
            ) {
                meals.append(meal)
            }
        }
        
        return meals
    }
    
    private func getMealTypesForDay(mealsPerDay: Int, dayOffset: Int) -> [MealType] {
        switch mealsPerDay {
        case 2:
            // For 2 meals, typically breakfast and dinner
            return [.breakfast, .dinner]
        case 3:
            // For 3 meals, standard breakfast, lunch, dinner
            return [.breakfast, .lunch, .dinner]
        case 4:
            // For 4 meals, add a snack
            return [.breakfast, .lunch, .dinner, .snack]
        default:
            return [.breakfast, .lunch, .dinner]
        }
    }
    
    private func generateMeal(
        type: MealType,
        availableRecipes: [Recipe],
        inputs: AutoFillInputs,
        existingMeals: [Meal]
    ) -> Meal? {
        
        // Filter recipes by meal type
        let mealTypeRecipes = filterRecipesByMealType(availableRecipes, type: type)
        
        // Apply variety constraints (avoid repetition)
        let varietyFilteredRecipes = applyVarietyConstraints(
            mealTypeRecipes,
            existingMeals: existingMeals,
            dayOffset: 0 // This would be more sophisticated in a real implementation
        )
        
        // Select the best recipe based on scoring
        guard let selectedRecipe = selectBestRecipe(varietyFilteredRecipes, inputs: inputs) else {
            // Fallback: create a custom meal
            return createCustomMeal(type: type, inputs: inputs)
        }
        
        // Scale recipe for number of people
        let scaledRecipe = selectedRecipe.scaledRecipe(for: inputs.numberOfPeople)
        
        // Convert recipe ingredients to grocery items
        let ingredients = scaledRecipe.ingredients.map { ingredient in
            GroceryItem(
                name: ingredient.name,
                description: ingredient.notes ?? "",
                price: ingredient.estimatedPrice,
                category: getCategoryForIngredient(ingredient.name),
                aisle: ingredient.aisle,
                brand: ""
            )
        }
        
        return Meal(
            date: Date(),
            type: type,
            recipeName: scaledRecipe.name,
            ingredients: ingredients.map { $0.name },
            recipe: scaledRecipe,
            customMeal: nil
        )
    }
    
    // MARK: - Recipe Filtering
    private func filterRecipesForConstraints(inputs: AutoFillInputs) -> [Recipe] {
        return RecipeDatabase.recipes.filter { recipe in
            // Time constraint
            guard recipe.totalTime <= inputs.timeConstraint.maxMinutes else { return false }
            
            // Budget constraint (per meal)
            let mealCost = recipe.estimatedCost * Double(inputs.numberOfPeople)
            let maxMealCost = inputs.budgetRange.maxWeeklyBudget / 7.0 / Double(inputs.mealsPerDay)
            guard mealCost <= maxMealCost else { return false }
            
            // Dietary preferences
            return matchesDietaryPreferences(recipe, preferences: inputs.dietaryPreferences)
        }
    }
    
    private func filterRecipesByMealType(_ recipes: [Recipe], type: MealType) -> [Recipe] {
        return recipes.filter { recipe in
            switch type {
            case .breakfast:
                return recipe.category == .breakfast || recipe.tags.contains("breakfast")
            case .lunch:
                return recipe.category == .lunch || recipe.category == .salad || recipe.tags.contains("lunch")
            case .dinner:
                return recipe.category == .dinner || recipe.category == .pasta || recipe.category == .meat || recipe.category == .seafood || recipe.tags.contains("dinner")
            case .snack:
                return recipe.category == .snack || recipe.tags.contains("snack")
            }
        }
    }
    
    private func matchesDietaryPreferences(_ recipe: Recipe, preferences: Set<DietaryPreference>) -> Bool {
        guard !preferences.isEmpty else { return true }
        
        for preference in preferences {
            switch preference {
            case .vegetarian:
                if !recipe.dietaryInfo.isVegetarian { return false }
            case .vegan:
                if !recipe.dietaryInfo.isVegan { return false }
            case .glutenFree:
                if !recipe.dietaryInfo.isGlutenFree { return false }
            case .dairyFree:
                if !recipe.dietaryInfo.isDairyFree { return false }
            case .lowCarb:
                if (recipe.nutritionInfo.carbs ?? 0) > 30 { return false }
            case .highProtein:
                if (recipe.nutritionInfo.protein ?? 0) < 20 { return false }
            case .keto:
                if !recipe.dietaryInfo.isKeto { return false }
            case .paleo:
                if !recipe.dietaryInfo.isPaleo { return false }
            }
        }
        
        return true
    }
    
    // MARK: - Variety and Balance Logic
    private func applyVarietyConstraints(
        _ recipes: [Recipe],
        existingMeals: [Meal],
        dayOffset: Int
    ) -> [Recipe] {
        // Simple variety logic: avoid repeating the same recipe type
        let existingRecipeNames = existingMeals.compactMap { $0.recipe?.name }
        let _ = existingMeals.compactMap { $0.recipe?.category }
        
        return recipes.filter { recipe in
            // Avoid exact recipe repetition
            !existingRecipeNames.contains(recipe.name)
        }
    }
    
    // MARK: - Recipe Selection
    private func selectBestRecipe(_ recipes: [Recipe], inputs: AutoFillInputs) -> Recipe? {
        guard !recipes.isEmpty else { return nil }
        
        // Score recipes based on multiple factors
        let scoredRecipes = recipes.map { recipe in
            (recipe: recipe, score: calculateRecipeScore(recipe, inputs: inputs))
        }
        
        // Sort by score and return the best one
        let sortedRecipes = scoredRecipes.sorted { $0.score > $1.score }
        return sortedRecipes.first?.recipe
    }
    
    private func calculateRecipeScore(_ recipe: Recipe, inputs: AutoFillInputs) -> Double {
        var score = 0.0
        
        // Rating score (0-5)
        score += recipe.rating * 2.0
        
        // Popularity score (based on review count)
        score += min(Double(recipe.reviewCount) / 1000.0, 5.0)
        
        // Time efficiency score (faster is better)
        let timeScore = max(0, 10.0 - Double(recipe.totalTime) / 5.0)
        score += timeScore
        
        // Cost efficiency score (cheaper is better)
        let costScore = max(0, 10.0 - recipe.estimatedCost / 2.0)
        score += costScore
        
        // Nutritional balance score
        let nutritionScore = calculateNutritionScore(recipe)
        score += nutritionScore
        
        return score
    }
    
    private func calculateNutritionScore(_ recipe: Recipe) -> Double {
        var score = 0.0
        
        // Protein score
        if (recipe.nutritionInfo.protein ?? 0) >= 20 {
            score += 2.0
        } else if (recipe.nutritionInfo.protein ?? 0) >= 10 {
            score += 1.0
        }
        
        // Fiber score
        if let fiber = recipe.nutritionInfo.fiber, fiber >= 5 {
            score += 1.0
        }
        
        // Balanced macronutrients
        let totalCalories = Double(recipe.nutritionInfo.calories ?? 0)
        let proteinRatio = (recipe.nutritionInfo.protein ?? 0) * 4 / totalCalories
        let carbRatio = (recipe.nutritionInfo.carbs ?? 0) * 4 / totalCalories
        let fatRatio = (recipe.nutritionInfo.fat ?? 0) * 9 / totalCalories
        
        if proteinRatio >= 0.15 && proteinRatio <= 0.35 {
            score += 1.0
        }
        if carbRatio >= 0.30 && carbRatio <= 0.65 {
            score += 1.0
        }
        if fatRatio >= 0.20 && fatRatio <= 0.40 {
            score += 1.0
        }
        
        return score
    }
    
    // MARK: - Fallback Methods
    private func createCustomMeal(type: MealType, inputs: AutoFillInputs) -> Meal {
        let customMealName = getCustomMealName(type: type, inputs: inputs)
        let ingredients = getDefaultIngredients(type: type, inputs: inputs)
        
        return Meal(
            date: Date(),
            type: type,
            recipeName: customMealName,
            ingredients: ingredients.map { $0.name },
            recipe: nil,
            customMeal: customMealName
        )
    }
    
    private func getCustomMealName(type: MealType, inputs: AutoFillInputs) -> String {
        switch type {
        case .breakfast:
            return "Healthy Breakfast Bowl"
        case .lunch:
            return "Fresh Salad with Protein"
        case .dinner:
            return "Balanced Dinner Plate"
        case .snack:
            return "Nutritious Snack"
        }
    }
    
    private func getDefaultIngredients(type: MealType, inputs: AutoFillInputs) -> [GroceryItem] {
        switch type {
        case .breakfast:
            return [
                GroceryItem(name: "Eggs", description: "Fresh eggs", price: 2.99, category: "Dairy", aisle: 5, brand: ""),
                GroceryItem(name: "Whole Grain Bread", description: "Healthy bread", price: 3.49, category: "Bakery", aisle: 3, brand: ""),
                GroceryItem(name: "Fresh Fruit", description: "Seasonal fruit", price: 4.99, category: "Produce", aisle: 1, brand: "")
            ]
        case .lunch:
            return [
                GroceryItem(name: "Mixed Greens", description: "Fresh salad greens", price: 2.99, category: "Produce", aisle: 1, brand: ""),
                GroceryItem(name: "Chicken Breast", description: "Lean protein", price: 8.97, category: "Meat", aisle: 4, brand: ""),
                GroceryItem(name: "Olive Oil", description: "For dressing", price: 1.50, category: "Pantry", aisle: 2, brand: "")
            ]
        case .dinner:
            return [
                GroceryItem(name: "Salmon Fillet", description: "Fresh fish", price: 12.99, category: "Seafood", aisle: 4, brand: ""),
                GroceryItem(name: "Brown Rice", description: "Whole grain", price: 2.99, category: "Pantry", aisle: 3, brand: ""),
                GroceryItem(name: "Broccoli", description: "Fresh vegetables", price: 2.99, category: "Produce", aisle: 1, brand: "")
            ]
        case .snack:
            return [
                GroceryItem(name: "Greek Yogurt", description: "Protein-rich", price: 3.99, category: "Dairy", aisle: 5, brand: ""),
                GroceryItem(name: "Mixed Nuts", description: "Healthy fats", price: 5.99, category: "Pantry", aisle: 2, brand: "")
            ]
        }
    }
    
    // MARK: - Helper Methods
    private func getCategoryForIngredient(_ ingredientName: String) -> String {
        let lowercased = ingredientName.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("pork") {
            return "Meat"
        } else if lowercased.contains("salmon") || lowercased.contains("fish") || lowercased.contains("shrimp") {
            return "Seafood"
        } else if lowercased.contains("milk") || lowercased.contains("cheese") || lowercased.contains("yogurt") {
            return "Dairy"
        } else if lowercased.contains("apple") || lowercased.contains("banana") || lowercased.contains("berry") {
            return "Produce"
        } else if lowercased.contains("rice") || lowercased.contains("pasta") || lowercased.contains("bread") {
            return "Grains"
        } else {
            return "Pantry"
        }
    }
} 