//
//  MealPlanManager.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import Foundation

class MealPlanManager: ObservableObject {
    static func sampleMealPlans() -> [MealPlan] {
        let recipes = RecipeDatabase.recipes
        
        return [
            MealPlan(
                date: Date(),
                meals: [
                    MealPlan.Meal(
                        type: .breakfast,
                        recipe: recipes.first,
                        customMeal: nil,
                        ingredients: sampleGroceryItems.prefix(3).map { $0 }
                    ),
                    MealPlan.Meal(
                        type: .lunch,
                        recipe: recipes.dropFirst().first,
                        customMeal: nil,
                        ingredients: sampleGroceryItems.dropFirst(3).prefix(4).map { $0 }
                    ),
                    MealPlan.Meal(
                        type: .dinner,
                        recipe: recipes.dropFirst(2).first,
                        customMeal: nil,
                        ingredients: sampleGroceryItems.dropFirst(7).prefix(5).map { $0 }
                    )
                ],
                notes: "Healthy week ahead! Focus on protein and vegetables."
            ),
            MealPlan(
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                meals: [
                    MealPlan.Meal(
                        type: .breakfast,
                        recipe: nil,
                        customMeal: "Oatmeal with berries and nuts",
                        ingredients: sampleGroceryItems.filter { $0.name.contains("Oat") || $0.name.contains("Berry") }.prefix(3).map { $0 }
                    ),
                    MealPlan.Meal(
                        type: .lunch,
                        recipe: nil,
                        customMeal: "Grilled chicken salad",
                        ingredients: sampleGroceryItems.filter { $0.name.contains("Chicken") || $0.name.contains("Lettuce") }.prefix(4).map { $0 }
                    ),
                    MealPlan.Meal(
                        type: .dinner,
                        recipe: recipes.dropFirst(3).first,
                        customMeal: nil,
                        ingredients: sampleGroceryItems.dropFirst(12).prefix(6).map { $0 }
                    )
                ],
                notes: "Quick and easy meals for busy day."
            )
        ]
    }
    
    static func generateShoppingList(from mealPlan: MealPlan) -> [GroceryItem] {
        var allIngredients: [GroceryItem] = []
        
        for meal in mealPlan.meals {
            allIngredients.append(contentsOf: meal.ingredients)
        }
        
        // Remove duplicates and group by item
        let groupedIngredients = Dictionary(grouping: allIngredients) { $0.name }
        return groupedIngredients.map { _, items in
            let firstItem = items.first!
            return GroceryItem(
                name: firstItem.name,
                description: firstItem.description,
                price: firstItem.price,
                category: firstItem.category,
                aisle: firstItem.aisle,
                brand: firstItem.brand
            )
        }
    }
    
    static func scaleRecipe(_ recipe: Recipe, by factor: Double) -> Recipe {
        var scaledRecipe = recipe
        scaledRecipe.ingredients = recipe.ingredients.map { ingredient in
            var scaledIngredient = ingredient
            // Scale the amount property, not quantity
            scaledIngredient = RecipeIngredient(
                id: ingredient.id,
                name: ingredient.name,
                amount: ingredient.amount * factor,
                unit: ingredient.unit,
                aisle: ingredient.aisle,
                estimatedPrice: ingredient.estimatedPrice * factor,
                notes: ingredient.notes
            )
            return scaledIngredient
        }
        scaledRecipe.servings = Int(Double(recipe.servings) * factor)
        return scaledRecipe
    }
    
    static func suggestLeftoverRecipes(for ingredients: [GroceryItem]) -> [Recipe] {
        let recipes = RecipeDatabase.recipes
        
        // Simple matching based on ingredient names
        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
            let availableIngredients = ingredients.map { $0.name.lowercased() }
            
            // Check if at least 60% of recipe ingredients are available
            let matchingIngredients = recipeIngredients.filter { recipeIngredient in
                availableIngredients.contains { availableIngredient in
                    availableIngredient.contains(recipeIngredient) || recipeIngredient.contains(availableIngredient)
                }
            }
            
            return Double(matchingIngredients.count) / Double(recipeIngredients.count) >= 0.6
        }
    }
}

// MARK: - Shopping History Manager
class ShoppingHistoryManager {
    static func sampleHistory() -> [ShoppingHistory] {
        return [
            ShoppingHistory(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                items: sampleGroceryItems.prefix(8).map { $0 },
                totalSpent: 45.67,
                store: "Whole Foods Market",
                category: "Weekly Groceries"
            ),
            ShoppingHistory(
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                items: sampleGroceryItems.dropFirst(8).prefix(12).map { $0 },
                totalSpent: 78.92,
                store: "Trader Joe's",
                category: "Weekly Groceries"
            ),
            ShoppingHistory(
                date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                items: sampleGroceryItems.dropFirst(20).prefix(6).map { $0 },
                totalSpent: 23.45,
                store: "Safeway",
                category: "Quick Trip"
            )
        ]
    }
}

// MARK: - Dietary Goal Manager
class DietaryGoalManager {
    static func sampleGoals() -> [DietaryGoal] {
        return [
            DietaryGoal(
                type: .calories,
                target: 2000,
                current: 1850,
                unit: "cal",
                isActive: true
            ),
            DietaryGoal(
                type: .protein,
                target: 150,
                current: 120,
                unit: "g",
                isActive: true
            ),
            DietaryGoal(
                type: .fiber,
                target: 25,
                current: 18,
                unit: "g",
                isActive: true
            ),
            DietaryGoal(
                type: .sugar,
                target: 50,
                current: 65,
                unit: "g",
                isActive: true
            )
        ]
    }
}

// MARK: - Store Info Manager
class StoreInfoManager {
    static func sampleStoreInfo() -> [StoreInfo] {
        return [
            StoreInfo(
                name: "Whole Foods Market",
                address: "123 Main St, Los Angeles, CA 90210",
                hours: "7:00 AM - 10:00 PM",
                phone: "(310) 555-0123",
                rating: 4.5,
                reviews: [
                    StoreInfo.StoreReview(
                        rating: 5,
                        comment: "Great selection of organic products!",
                        date: Date(),
                        author: "Sarah M."
                    ),
                    StoreInfo.StoreReview(
                        rating: 4,
                        comment: "A bit pricey but quality is excellent",
                        date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                        author: "Mike R."
                    )
                ],
                parkingInfo: "Free parking in attached garage",
                accessibility: ["Wheelchair accessible", "Assistance available", "Wide aisles"]
            ),
            StoreInfo(
                name: "Trader Joe's",
                address: "456 Oak Ave, Los Angeles, CA 90211",
                hours: "8:00 AM - 9:00 PM",
                phone: "(310) 555-0456",
                rating: 4.8,
                reviews: [
                    StoreInfo.StoreReview(
                        rating: 5,
                        comment: "Love their unique products and friendly staff!",
                        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        author: "Jennifer L."
                    )
                ],
                parkingInfo: "Street parking and small lot",
                accessibility: ["Wheelchair accessible", "Narrow aisles"]
            )
        ]
    }
}

// MARK: - Notification Manager
class NotificationManager {
    static func sampleNotifications() -> [SmartNotification] {
        return [
            SmartNotification(
                type: .priceDrop,
                title: "Price Drop Alert!",
                message: "Organic Bananas are now 20% off at Whole Foods",
                date: Date(),
                isRead: false,
                action: .viewDeal
            ),
            SmartNotification(
                type: .dietaryGoal,
                title: "Goal Progress",
                message: "You're 80% to your daily protein goal. Consider adding chicken to your list.",
                date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isRead: false,
                action: .addToList
            ),
            SmartNotification(
                type: .mealReminder,
                title: "Meal Planning",
                message: "Time to plan your meals for next week!",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRead: true
            )
        ]
    }
}

// MARK: - Shopping Insights
struct ShoppingInsights {
    let title: String
    let message: String
    let type: String
    
    static func generateInsights(from history: [ShoppingHistory]) -> [ShoppingInsights] {
        var insights: [ShoppingInsights] = []
        
        // Analyze spending patterns
        let totalSpent = history.reduce(0) { $0 + $1.totalSpent }
        let averageSpent = totalSpent / Double(max(history.count, 1))
        
        if averageSpent > 60 {
            insights.append(ShoppingInsights(
                title: "High Spending Alert",
                message: "Your average shopping trip is $\(String(format: "%.2f", averageSpent)). Consider meal planning to reduce costs.",
                type: "Budget"
            ))
        }
        
        // Analyze store preferences
        let storeCounts = Dictionary(grouping: history) { $0.store }.mapValues { $0.count }
        if let favoriteStore = storeCounts.max(by: { $0.value < $1.value }) {
            insights.append(ShoppingInsights(
                title: "Store Preference",
                message: "You shop most frequently at \(favoriteStore.key). Consider checking other stores for better deals.",
                type: "Savings"
            ))
        }
        
        // Analyze shopping frequency
        if history.count >= 2 {
            let sortedHistory = history.sorted { $0.date > $1.date }
            let daysBetween = Calendar.current.dateComponents([.day], from: sortedHistory[1].date, to: sortedHistory[0].date).day ?? 0
            
            if daysBetween > 10 {
                insights.append(ShoppingInsights(
                    title: "Shopping Reminder",
                    message: "It's been \(daysBetween) days since your last shopping trip. Time to restock?",
                    type: "Reminder"
                ))
            }
        }
        
        return insights
    }
} 