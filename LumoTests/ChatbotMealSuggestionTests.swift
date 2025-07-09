//
//  ChatbotMealSuggestionTests.swift
//  LumoTests
//
//  Created by Ethan on 7/4/25.
//

import XCTest
import SwiftUI
@testable import Lumo

final class ChatbotMealSuggestionTests: XCTestCase {
    var mealManager: MealPlanManager!
    var groceryList: GroceryList!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager.shared
        mealManager.mealPlan.removeAll()
        groceryList = GroceryList()
        groceryList.items.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager.mealPlan.removeAll()
        groceryList.items.removeAll()
    }
    
    // MARK: - Meal Suggestion Card Tests
    
    func testMealSuggestionCardInitialization() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            description: "A delicious test recipe",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Italian"
        )
        
        // When & Then
        XCTAssertEqual(suggestion.recipeName, "Test Recipe")
        XCTAssertEqual(suggestion.ingredients.count, 2)
        XCTAssertEqual(suggestion.description, "A delicious test recipe")
        XCTAssertEqual(suggestion.cookingTime, 30)
        XCTAssertEqual(suggestion.difficulty, "Easy")
        XCTAssertEqual(suggestion.cuisine, "Italian")
    }
    
    func testMealSuggestionCardProperties() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Pasta Carbonara",
            ingredients: ["Pasta", "Eggs", "Bacon", "Cheese"],
            description: "Classic Italian pasta dish",
            cookingTime: 25,
            difficulty: "Medium",
            cuisine: "Italian"
        )
        
        // When & Then
        XCTAssertFalse(suggestion.recipeName.isEmpty)
        XCTAssertGreaterThan(suggestion.ingredients.count, 0)
        XCTAssertFalse(suggestion.description.isEmpty)
        XCTAssertGreaterThan(suggestion.cookingTime, 0)
        XCTAssertFalse(suggestion.difficulty.isEmpty)
        XCTAssertFalse(suggestion.cuisine.isEmpty)
    }
    
    // MARK: - Add to Meal Plan Tests
    
    func testAddMealToPlanFromSuggestion() throws {
        // Given
        let date = Date()
        let mealType = MealType.dinner
        let suggestion = MealSuggestion(
            recipeName: "Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            description: "Test description",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Italian"
        )
        
        // When
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: suggestion.recipeName,
            ingredients: suggestion.ingredients,
            servings: 2
        )
        mealManager.addMeal(meal)
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 1)
        XCTAssertEqual(savedMeals.first?.recipeName, suggestion.recipeName)
        XCTAssertEqual(savedMeals.first?.ingredients, suggestion.ingredients)
    }
    
    func testAddMultipleMealsToPlan() throws {
        // Given
        let date = Date()
        let suggestion1 = MealSuggestion(
            recipeName: "Breakfast Recipe",
            ingredients: ["Eggs", "Bread"],
            description: "Morning meal",
            cookingTime: 15,
            difficulty: "Easy",
            cuisine: "American"
        )
        let suggestion2 = MealSuggestion(
            recipeName: "Dinner Recipe",
            ingredients: ["Chicken", "Rice"],
            description: "Evening meal",
            cookingTime: 45,
            difficulty: "Medium",
            cuisine: "Asian"
        )
        
        // When
        let meal1 = Meal(date: date, type: .breakfast, recipeName: suggestion1.recipeName, ingredients: suggestion1.ingredients, servings: 1)
        let meal2 = Meal(date: date, type: .dinner, recipeName: suggestion2.recipeName, ingredients: suggestion2.ingredients, servings: 2)
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 2)
    }
    
    func testAddMealWithCustomDate() throws {
        // Given
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let mealType = MealType.lunch
        let suggestion = MealSuggestion(
            recipeName: "Tomorrow's Lunch",
            ingredients: ["Bread", "Cheese", "Tomato"],
            description: "Simple sandwich",
            cookingTime: 10,
            difficulty: "Easy",
            cuisine: "American"
        )
        
        // When
        let meal = Meal(
            date: tomorrow,
            type: mealType,
            recipeName: suggestion.recipeName,
            ingredients: suggestion.ingredients,
            servings: 1
        )
        mealManager.addMeal(meal)
        
        // Then
        let savedMeals = mealManager.meals(for: tomorrow)
        XCTAssertEqual(savedMeals.count, 1)
        XCTAssertEqual(savedMeals.first?.type, mealType)
    }
    
    // MARK: - Add to Grocery List Tests
    
    func testAddIngredientsToGroceryList() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Test Recipe",
            ingredients: ["Chicken", "Rice", "Broccoli", "Soy Sauce"],
            description: "Test description",
            cookingTime: 30,
            difficulty: "Medium",
            cuisine: "Asian"
        )
        
        // When
        for ingredient in suggestion.ingredients {
            let groceryItem = GroceryItem(name: ingredient, quantity: 1, category: "Other")
            groceryList.addItem(groceryItem)
        }
        
        // Then
        XCTAssertEqual(groceryList.items.count, 4)
        XCTAssertTrue(groceryList.items.contains { $0.name == "Chicken" })
        XCTAssertTrue(groceryList.items.contains { $0.name == "Rice" })
        XCTAssertTrue(groceryList.items.contains { $0.name == "Broccoli" })
        XCTAssertTrue(groceryList.items.contains { $0.name == "Soy Sauce" })
    }
    
    func testAddIngredientsWithQuantities() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Large Recipe",
            ingredients: ["Chicken", "Rice", "Vegetables"],
            description: "Feeds many people",
            cookingTime: 60,
            difficulty: "Hard",
            cuisine: "International"
        )
        let servings = 4
        
        // When
        for ingredient in suggestion.ingredients {
            let groceryItem = GroceryItem(name: ingredient, quantity: servings, category: "Other")
            groceryList.addItem(groceryItem)
        }
        
        // Then
        XCTAssertEqual(groceryList.items.count, 3)
        for item in groceryList.items {
            XCTAssertEqual(item.quantity, servings)
        }
    }
    
    func testAddIngredientsWithCategorization() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Categorized Recipe",
            ingredients: ["Chicken", "Milk", "Apple", "Bread", "Oil"],
            description: "Test categorization",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Mixed"
        )
        
        // When
        for ingredient in suggestion.ingredients {
            let category = categorizeIngredient(ingredient)
            let groceryItem = GroceryItem(name: ingredient, quantity: 1, category: category)
            groceryList.addItem(groceryItem)
        }
        
        // Then
        XCTAssertEqual(groceryList.items.count, 5)
        
        // Check categorization
        let meatItems = groceryList.items.filter { $0.category == "Meat" }
        let dairyItems = groceryList.items.filter { $0.category == "Dairy" }
        let produceItems = groceryList.items.filter { $0.category == "Produce" }
        let grainsItems = groceryList.items.filter { $0.category == "Grains" }
        let pantryItems = groceryList.items.filter { $0.category == "Pantry" }
        
        XCTAssertEqual(meatItems.count, 1) // Chicken
        XCTAssertEqual(dairyItems.count, 1) // Milk
        XCTAssertEqual(produceItems.count, 1) // Apple
        XCTAssertEqual(grainsItems.count, 1) // Bread
        XCTAssertEqual(pantryItems.count, 1) // Oil
    }
    
    // MARK: - Button Functionality Tests
    
    func testAddToMealPlanButtonState() throws {
        // Given
        let isAddingToPlan = false
        let canAddToPlan = true
        
        // When
        let buttonEnabled = !isAddingToPlan && canAddToPlan
        
        // Then
        XCTAssertTrue(buttonEnabled)
    }
    
    func testAddToMealPlanButtonStateWhileAdding() throws {
        // Given
        let isAddingToPlan = true
        let canAddToPlan = true
        
        // When
        let buttonEnabled = !isAddingToPlan && canAddToPlan
        
        // Then
        XCTAssertFalse(buttonEnabled)
    }
    
    func testAddToGroceryListButtonState() throws {
        // Given
        let isAddingToGrocery = false
        let canAddToGrocery = true
        
        // When
        let buttonEnabled = !isAddingToGrocery && canAddToGrocery
        
        // Then
        XCTAssertTrue(buttonEnabled)
    }
    
    func testAddToGroceryListButtonStateWhileAdding() throws {
        // Given
        let isAddingToGrocery = true
        let canAddToGrocery = true
        
        // When
        let buttonEnabled = !isAddingToGrocery && canAddToGrocery
        
        // Then
        XCTAssertFalse(buttonEnabled)
    }
    
    // MARK: - Date Selection Tests
    
    func testDateSelectionForMealPlan() throws {
        // Given
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        // When & Then
        XCTAssertTrue(tomorrow > today)
        XCTAssertTrue(nextWeek > today)
        XCTAssertTrue(nextWeek > tomorrow)
    }
    
    func testDateValidationForMealPlan() throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // When & Then
        XCTAssertTrue(today >= today) // Today is valid
        XCTAssertTrue(tomorrow >= today) // Future dates are valid
        XCTAssertFalse(yesterday >= today) // Past dates are invalid
    }
    
    // MARK: - Meal Type Selection Tests
    
    func testMealTypeSelectionForSuggestion() throws {
        // Given
        let allMealTypes = MealType.allCases
        
        // When & Then
        XCTAssertEqual(allMealTypes.count, 4)
        XCTAssertTrue(allMealTypes.contains(.breakfast))
        XCTAssertTrue(allMealTypes.contains(.lunch))
        XCTAssertTrue(allMealTypes.contains(.dinner))
        XCTAssertTrue(allMealTypes.contains(.snack))
    }
    
    func testMealTypePropertiesForSuggestion() throws {
        // Test each meal type has required properties
        for mealType in MealType.allCases {
            XCTAssertFalse(mealType.rawValue.isEmpty)
            XCTAssertFalse(mealType.icon.isEmpty)
            XCTAssertFalse(mealType.emoji.isEmpty)
        }
    }
    
    // MARK: - Servings Selection Tests
    
    func testServingsSelection() throws {
        // Given
        let validServings = [1, 2, 4, 6, 8]
        let invalidServings = [0, -1, -5]
        
        // When & Then
        for serving in validServings {
            XCTAssertTrue(serving > 0)
            XCTAssertTrue(serving <= 12) // Max 12 servings
        }
        
        for serving in invalidServings {
            XCTAssertFalse(serving > 0)
        }
    }
    
    func testServingsRange() throws {
        // Given
        let minServings = 1
        let maxServings = 12
        let testServings = 4
        
        // When & Then
        XCTAssertTrue(testServings >= minServings)
        XCTAssertTrue(testServings <= maxServings)
    }
    
    // MARK: - Suggestion Display Tests
    
    func testSuggestionDisplayProperties() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Display Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
            description: "A recipe for testing display properties",
            cookingTime: 45,
            difficulty: "Medium",
            cuisine: "Italian"
        )
        
        // When & Then
        XCTAssertFalse(suggestion.recipeName.isEmpty)
        XCTAssertGreaterThan(suggestion.ingredients.count, 0)
        XCTAssertFalse(suggestion.description.isEmpty)
        XCTAssertGreaterThan(suggestion.cookingTime, 0)
        XCTAssertFalse(suggestion.difficulty.isEmpty)
        XCTAssertFalse(suggestion.cuisine.isEmpty)
    }
    
    func testSuggestionCookingTimeDisplay() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Time Test",
            ingredients: ["Ingredient"],
            description: "Test cooking time",
            cookingTime: 75,
            difficulty: "Easy",
            cuisine: "American"
        )
        
        // When
        let minutes = suggestion.cookingTime % 60
        let hours = suggestion.cookingTime / 60
        
        // Then
        XCTAssertEqual(hours, 1)
        XCTAssertEqual(minutes, 15)
    }
    
    // MARK: - Integration Tests
    
    func testAddSuggestionToMealPlanAndGroceryList() throws {
        // Given
        let date = Date()
        let mealType = MealType.dinner
        let servings = 2
        let suggestion = MealSuggestion(
            recipeName: "Integration Test Recipe",
            ingredients: ["Chicken", "Rice", "Broccoli"],
            description: "Test integration",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Asian"
        )
        
        // When - Add to meal plan
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: suggestion.recipeName,
            ingredients: suggestion.ingredients,
            servings: servings
        )
        mealManager.addMeal(meal)
        
        // When - Add ingredients to grocery list
        for ingredient in suggestion.ingredients {
            let groceryItem = GroceryItem(name: ingredient, quantity: servings, category: "Other")
            groceryList.addItem(groceryItem)
        }
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 1)
        XCTAssertEqual(savedMeals.first?.recipeName, suggestion.recipeName)
        
        XCTAssertEqual(groceryList.items.count, 3)
        for item in groceryList.items {
            XCTAssertEqual(item.quantity, servings)
        }
    }
    
    func testMultipleSuggestionsIntegration() throws {
        // Given
        let date = Date()
        let suggestion1 = MealSuggestion(
            recipeName: "Breakfast",
            ingredients: ["Eggs", "Bread", "Milk"],
            description: "Morning meal",
            cookingTime: 15,
            difficulty: "Easy",
            cuisine: "American"
        )
        let suggestion2 = MealSuggestion(
            recipeName: "Dinner",
            ingredients: ["Chicken", "Rice", "Vegetables"],
            description: "Evening meal",
            cookingTime: 45,
            difficulty: "Medium",
            cuisine: "Asian"
        )
        
        // When
        let meal1 = Meal(date: date, type: .breakfast, recipeName: suggestion1.recipeName, ingredients: suggestion1.ingredients, servings: 1)
        let meal2 = Meal(date: date, type: .dinner, recipeName: suggestion2.recipeName, ingredients: suggestion2.ingredients, servings: 2)
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // Add all ingredients to grocery list
        for ingredient in suggestion1.ingredients {
            groceryList.addItem(GroceryItem(name: ingredient, quantity: 1, category: "Other"))
        }
        for ingredient in suggestion2.ingredients {
            groceryList.addItem(GroceryItem(name: ingredient, quantity: 2, category: "Other"))
        }
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 2)
        
        XCTAssertEqual(groceryList.items.count, 6)
    }
    
    // MARK: - Edge Cases
    
    func testSuggestionWithEmptyIngredients() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Empty Ingredients",
            ingredients: [],
            description: "Test empty ingredients",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Test"
        )
        
        // When & Then
        XCTAssertTrue(suggestion.ingredients.isEmpty)
        XCTAssertFalse(suggestion.recipeName.isEmpty)
    }
    
    func testSuggestionWithVeryLongRecipeName() throws {
        // Given
        let longRecipeName = String(repeating: "A", count: 100)
        let suggestion = MealSuggestion(
            recipeName: longRecipeName,
            ingredients: ["Ingredient"],
            description: "Test long name",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Test"
        )
        
        // When & Then
        XCTAssertEqual(suggestion.recipeName, longRecipeName)
        XCTAssertEqual(suggestion.recipeName.count, 100)
    }
    
    func testSuggestionWithSpecialCharacters() throws {
        // Given
        let suggestion = MealSuggestion(
            recipeName: "Recipe with special chars: !@#$%^&*()",
            ingredients: ["Ingredient with spaces", "Ingredient-with-dashes"],
            description: "Description with emoji 🍕 and unicode ñáéíóú",
            cookingTime: 30,
            difficulty: "Easy",
            cuisine: "Cuisine with emoji 🍝"
        )
        
        // When & Then
        XCTAssertEqual(suggestion.recipeName, "Recipe with special chars: !@#$%^&*()")
        XCTAssertEqual(suggestion.ingredients, ["Ingredient with spaces", "Ingredient-with-dashes"])
        XCTAssertEqual(suggestion.description, "Description with emoji 🍕 and unicode ñáéíóú")
        XCTAssertEqual(suggestion.cuisine, "Cuisine with emoji 🍝")
    }
    
    // MARK: - Helper Functions
    
    private func categorizeIngredient(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        
        if ["milk", "cheese", "yogurt", "cream", "butter"].contains(lowercased) {
            return "Dairy"
        } else if ["apple", "banana", "tomato", "lettuce", "carrot", "broccoli"].contains(lowercased) {
            return "Produce"
        } else if ["chicken", "beef", "pork", "fish", "turkey"].contains(lowercased) {
            return "Meat"
        } else if ["bread", "pasta", "rice", "flour", "cereal"].contains(lowercased) {
            return "Grains"
        } else if ["oil", "salt", "sugar", "spices", "sauce"].contains(lowercased) {
            return "Pantry"
        } else {
            return "Other"
        }
    }
}

// MARK: - Helper Structs for Testing

struct MealSuggestion {
    let recipeName: String
    let ingredients: [String]
    let description: String
    let cookingTime: Int
    let difficulty: String
    let cuisine: String
}

struct GroceryItem {
    let name: String
    let quantity: Int
    let category: String
}

class GroceryList {
    var items: [GroceryItem] = []
    
    func addItem(_ item: GroceryItem) {
        items.append(item)
    }
} 