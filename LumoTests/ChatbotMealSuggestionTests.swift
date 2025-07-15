//
//  ChatbotMealSuggestionTests.swift
//  LumoTests
//
//  Created by Assistant on 7/14/25.
//

import XCTest
@testable import Lumo

@MainActor
final class ChatbotMealSuggestionTests: XCTestCase {
    
    var mealManager: MealPlanManager!
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        mealManager = MealPlanManager()
        appState = AppState()
    }
    
    override func tearDown() {
        mealManager = nil
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Chat Action Tests
    
    func testAddMealFromChatAction() {
        // Given
        let recipe = createTestRecipe()
        let today = Date()
        
        // Simulate the chat action for adding to meal plan
        let meal = Meal(
            date: today,
            type: .dinner,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: recipe.servings
        )
        
        let initialCount = mealManager.meals(for: today).count
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let finalCount = mealManager.meals(for: today).count
        XCTAssertEqual(finalCount, initialCount + 1)
        
        let addedMeal = mealManager.meals(for: today).first { $0.recipeName == recipe.name }
        XCTAssertNotNil(addedMeal)
        XCTAssertEqual(addedMeal?.type, .dinner)
        XCTAssertEqual(addedMeal?.recipe?.id, recipe.id)
    }
    
    func testAddMealPlanAction() {
        // Given
        let recipe = createTestRecipe()
        let today = Date()
        
        // This simulates the .mealPlan chat action
        let meal = Meal(
            date: today,
            type: .dinner,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: recipe.servings
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: today)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, recipe.name)
    }
    
    func testAddToMealPlanAction() {
        // Given
        let recipe = createTestRecipe()
        let today = Date()
        
        // This simulates the .addToMealPlan chat action
        let meal = Meal(
            date: today,
            type: .dinner,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: recipe.servings
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: today)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, recipe.name)
    }
    
    // MARK: - ChatMessage Tests
    
    func testChatMessageWithRecipe() {
        // Given
        let recipe = createTestRecipe()
        let actionButtons = [
            ChatActionButton(title: "Add to Meal Plan", action: .addToMealPlan, icon: "calendar.badge.plus"),
            ChatActionButton(title: "Add Ingredients", action: .addToList, icon: "cart.badge.plus")
        ]
        
        // When
        let message = ChatMessage(
            content: "Here's a great recipe for you!",
            isUser: false,
            recipe: recipe,
            actionButtons: actionButtons
        )
        
        // Then
        XCTAssertNotNil(message.recipe)
        XCTAssertEqual(message.recipe?.id, recipe.id)
        XCTAssertEqual(message.actionButtons.count, 2)
        XCTAssertTrue(message.actionButtons.contains { $0.action == .addToMealPlan })
        XCTAssertTrue(message.actionButtons.contains { $0.action == .addToList })
    }
    
    // MARK: - Date/Time Selection Tests
    
    func testMealAdditionWithSpecificDate() {
        // Given
        let recipe = createTestRecipe()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let meal = Meal(
            date: tomorrow,
            type: .breakfast,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: recipe.servings
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let todayMeals = mealManager.meals(for: Date())
        let tomorrowMeals = mealManager.meals(for: tomorrow)
        
        XCTAssertEqual(todayMeals.count, 0)
        XCTAssertEqual(tomorrowMeals.count, 1)
        XCTAssertEqual(tomorrowMeals.first?.type, .breakfast)
    }
    
    func testMealAdditionWithDifferentMealTypes() {
        // Given
        let recipe = createTestRecipe()
        let today = Date()
        
        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        
        // When
        for mealType in mealTypes {
            let meal = Meal(
                date: today,
                type: mealType,
                recipeName: "\(recipe.name) - \(mealType.rawValue)",
                ingredients: recipe.ingredients.map { $0.name },
                recipe: recipe,
                servings: recipe.servings
            )
            mealManager.addMeal(meal)
        }
        
        // Then
        let meals = mealManager.meals(for: today)
        XCTAssertEqual(meals.count, 4)
        
        for mealType in mealTypes {
            XCTAssertTrue(meals.contains { $0.type == mealType })
        }
    }
    
    // MARK: - Batch Planning Tests
    
    func testBatchMealAddition() {
        // Given
        let recipe = createTestRecipe()
        let startDate = Date()
        
        var mealsToAdd: [Meal] = []
        
        // Create meals for next 7 days
        for dayOffset in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) {
                let meal = Meal(
                    date: date,
                    type: .dinner,
                    recipeName: recipe.name,
                    ingredients: recipe.ingredients.map { $0.name },
                    recipe: recipe,
                    servings: recipe.servings
                )
                mealsToAdd.append(meal)
            }
        }
        
        // When
        for meal in mealsToAdd {
            mealManager.addMeal(meal)
        }
        
        // Then
        let weekMeals = mealManager.mealsForWeek(starting: startDate)
        XCTAssertEqual(weekMeals.count, 7)
        
        // Verify each day has the meal
        for dayOffset in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) {
                let dayMeals = mealManager.meals(for: date)
                XCTAssertEqual(dayMeals.count, 1)
                XCTAssertEqual(dayMeals.first?.recipeName, recipe.name)
            }
        }
    }
    
    func testBatchMealAdditionMultipleMealTypes() {
        // Given
        let recipe = createTestRecipe()
        let startDate = Date()
        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
        
        var mealsToAdd: [Meal] = []
        
        // Create meals for next 3 days, all meal types
        for dayOffset in 0..<3 {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) {
                for mealType in mealTypes {
                    let meal = Meal(
                        date: date,
                        type: mealType,
                        recipeName: "\(recipe.name) - \(mealType.rawValue)",
                        ingredients: recipe.ingredients.map { $0.name },
                        recipe: recipe,
                        servings: recipe.servings
                    )
                    mealsToAdd.append(meal)
                }
            }
        }
        
        // When
        for meal in mealsToAdd {
            mealManager.addMeal(meal)
        }
        
        // Then
        // Should have 9 meals total (3 days × 3 meal types)
        var totalMeals = 0
        for dayOffset in 0..<3 {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) {
                let dayMeals = mealManager.meals(for: date)
                totalMeals += dayMeals.count
                XCTAssertEqual(dayMeals.count, 3) // 3 meal types per day
            }
        }
        XCTAssertEqual(totalMeals, 9)
    }
    
    // MARK: - Error Handling Tests
    
    func testAddMealWithoutRecipe() {
        // Given
        let today = Date()
        let customMeal = Meal(
            date: today,
            type: .lunch,
            recipeName: "Custom Sandwich",
            ingredients: ["Bread", "Ham", "Cheese"],
            customMeal: "Custom Sandwich",
            servings: 1
        )
        
        // When
        mealManager.addMeal(customMeal)
        
        // Then
        let meals = mealManager.meals(for: today)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, "Custom Sandwich")
        XCTAssertEqual(meals.first?.customMeal, "Custom Sandwich")
        XCTAssertNil(meals.first?.recipe)
    }
    
    func testAddMealWithEmptyIngredients() {
        // Given
        let today = Date()
        let meal = Meal(
            date: today,
            type: .snack,
            recipeName: "Simple Snack",
            ingredients: [],
            servings: 1
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: today)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.ingredients.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestRecipe() -> Recipe {
        return Recipe(
            id: UUID(),
            name: "Test Chat Recipe",
            description: "A test recipe for chat integration testing",
            ingredients: [
                Ingredient(name: "Test Ingredient 1", amount: 1.0, unit: "cup"),
                Ingredient(name: "Test Ingredient 2", amount: 2.0, unit: "tsp"),
                Ingredient(name: "Test Ingredient 3", amount: 0.5, unit: "lb")
            ],
            instructions: ["Step 1: Prepare ingredients", "Step 2: Cook", "Step 3: Serve"],
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            difficulty: "Easy",
            cuisine: "Test",
            category: .dinner,
            tags: ["test", "chat"],
            nutritionInfo: NutritionInfo(calories: 300, protein: 15, carbs: 30, fat: 10),
            dietaryInfo: DietaryInfo(),
            rating: 4.8,
            reviewCount: 25,
            estimatedCost: 8.99,
            imageURL: nil
        )
    }
} 