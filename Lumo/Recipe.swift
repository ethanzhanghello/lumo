//
//  Recipe.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation

struct Recipe: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: RecipeCategory
    let difficulty: RecipeDifficulty
    let prepTime: Int // minutes
    let cookTime: Int // minutes
    var servings: Int
    var ingredients: [RecipeIngredient]
    let instructions: [String]
    let nutritionInfo: NutritionInfo
    let tags: [String]
    let imageURL: String?
    let rating: Double
    let reviewCount: Int
    let dietaryInfo: DietaryInfo
    let estimatedCost: Double
    let cuisine: String
    let author: String
    
    var totalTime: Int {
        prepTime + cookTime
    }
    
    func scaledRecipe(for servings: Int) -> Recipe {
        let scaleFactor = Double(servings) / Double(self.servings)
        
        let scaledIngredients = ingredients.map { ingredient in
            RecipeIngredient(
                name: ingredient.name,
                amount: ingredient.amount * scaleFactor,
                unit: ingredient.unit,
                aisle: ingredient.aisle,
                estimatedPrice: ingredient.estimatedPrice * scaleFactor,
                notes: ingredient.notes
            )
        }
        
        let scaledNutrition = NutritionInfo(
            calories: Int(Double(nutritionInfo.calories ?? 0) * scaleFactor),
            protein: (nutritionInfo.protein ?? 0.0) * scaleFactor,
            carbs: (nutritionInfo.carbs ?? 0.0) * scaleFactor,
            fat: (nutritionInfo.fat ?? 0.0) * scaleFactor,
            fiber: (nutritionInfo.fiber ?? 0.0) * scaleFactor,
            sugar: (nutritionInfo.sugar ?? 0.0) * scaleFactor,
            sodium: Double(nutritionInfo.sodium ?? 0.0) * scaleFactor
        )
        
        return Recipe(
            id: id,
            name: name,
            description: description,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            ingredients: scaledIngredients,
            instructions: instructions,
            nutritionInfo: scaledNutrition,
            tags: tags,
            imageURL: imageURL,
            rating: rating,
            reviewCount: reviewCount,
            dietaryInfo: dietaryInfo,
            estimatedCost: estimatedCost * scaleFactor,
            cuisine: cuisine,
            author: author
        )
    }
}

struct RecipeIngredient: Identifiable, Codable {
    var id = UUID()
    let name: String
    let amount: Double
    let unit: String
    let aisle: Int
    let estimatedPrice: Double
    let notes: String?
    
    var displayAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(amount)) \(unit)"
        } else {
            return "\(amount) \(unit)"
        }
    }
}

struct DietaryInfo: Codable {
    let isVegetarian: Bool
    let isVegan: Bool
    let isGlutenFree: Bool
    let isDairyFree: Bool
    let isNutFree: Bool
    let isKeto: Bool
    let isPaleo: Bool
    let allergens: [String]
    
    var dietaryTags: [String] {
        var tags: [String] = []
        if isVegetarian { tags.append("Vegetarian") }
        if isVegan { tags.append("Vegan") }
        if isGlutenFree { tags.append("Gluten-Free") }
        if isDairyFree { tags.append("Dairy-Free") }
        if isNutFree { tags.append("Nut-Free") }
        if isKeto { tags.append("Keto") }
        if isPaleo { tags.append("Paleo") }
        return tags
    }
}

enum RecipeCategory: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case dessert = "Dessert"
    case snack = "Snack"
    case appetizer = "Appetizer"
    case soup = "Soup"
    case salad = "Salad"
    case pasta = "Pasta"
    case meat = "Meat"
    case seafood = "Seafood"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case quickMeals = "Quick Meals"
    case slowCooker = "Slow Cooker"
    case baking = "Baking"
    case drinks = "Drinks"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .dessert: return "birthday.cake"
        case .snack: return "leaf"
        case .appetizer: return "fork.knife"
        case .soup: return "cup.and.saucer"
        case .salad: return "leaf.circle"
        case .pasta: return "circle.grid.2x2"
        case .meat: return "flame"
        case .seafood: return "fish"
        case .vegetarian: return "carrot"
        case .vegan: return "leaf.arrow.circlepath"
        case .quickMeals: return "bolt"
        case .slowCooker: return "timer"
        case .baking: return "birthday.cake.fill"
        case .drinks: return "wineglass"
        }
    }
}

enum RecipeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var icon: String {
        switch self {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "#00FF88"
        case .medium: return "#FFAA00"
        case .hard: return "#FF4444"
        }
    }
} 