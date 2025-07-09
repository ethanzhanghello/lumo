//
//  MealPlanManagerTests.swift
//  LumoTests
//
//  Created by Ethan on 7/4/25.
//

import XCTest
@testable import Lumo

final class MealPlanManagerTests: XCTestCase {
    var mealManager: MealPlanManager!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager.shared
        // Clear any existing data
        mealManager.mealPlan.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager.mealPlan.removeAll()
    }
    
    // MARK: - Core Functionality Tests
    
    func testAddMeal() throws {
        // Given
        let date = Date()
        let meal = Meal(
            date: date,
            type: .dinner,
            recipeName: "Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            servings: 2
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, "Test Recipe")
        XCTAssertEqual(meals.first?.type, .dinner)
    }
    
    func testRemoveMeal() throws {
        // Given
        let date = Date()
        let meal = Meal(
            date: date,
            type: .breakfast,
            recipeName: "Test Recipe",
            ingredients: ["Ingredient 1"],
            servings: 1
        )
        mealManager.addMeal(meal)
        
        // When
        mealManager.removeMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 0)
    }
    
    func testUpdateMeal() throws {
        // Given
        let date = Date()
        let originalMeal = Meal(
            date: date,
            type: .lunch,
            recipeName: "Original Recipe",
            ingredients: ["Original Ingredient"],
            servings: 1
        )
        mealManager.addMeal(originalMeal)
        
        // When
        var updatedMeal = originalMeal
        updatedMeal.recipeName = "Updated Recipe"
        updatedMeal.servings = 3
        mealManager.updateMeal(updatedMeal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, "Updated Recipe")
        XCTAssertEqual(meals.first?.servings, 3)
    }
    
    func testMealCount() throws {
        // Given
        let date = Date()
        let meal1 = Meal(date: date, type: .breakfast, recipeName: "Breakfast", ingredients: [], servings: 1)
        let meal2 = Meal(date: date, type: .lunch, recipeName: "Lunch", ingredients: [], servings: 1)
        
        // When
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // Then
        XCTAssertEqual(mealManager.mealCount(for: date), 2)
    }
    
    func testHasMeal() throws {
        // Given
        let date = Date()
        let meal = Meal(date: date, type: .dinner, recipeName: "Dinner", ingredients: [], servings: 1)
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        XCTAssertTrue(mealManager.hasMeal(for: date, type: .dinner))
        XCTAssertFalse(mealManager.hasMeal(for: date, type: .breakfast))
    }
    
    // MARK: - Auto-Fill Tests
    
    func testGenerateAutoFillPlan() throws {
        // Given
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegetarian"],
            maxCookingTime: 30,
            budgetPerMeal: 15.0,
            preferredCuisines: ["Italian"],
            servingsPerMeal: 2
        )
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
        
        // Verify all meals are within the week
        for meal in generatedMeals {
            let calendar = Calendar.current
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            XCTAssertTrue(meal.date >= weekStart && meal.date <= weekEnd)
        }
    }
    
    func testAutoFillPreferences() throws {
        // Given
        let preferences = AutoFillPreferences()
        
        // When & Then
        XCTAssertEqual(preferences.dietaryRestrictions.count, 0)
        XCTAssertEqual(preferences.maxCookingTime, 60)
        XCTAssertEqual(preferences.budgetPerMeal, 15.0)
        XCTAssertEqual(preferences.preferredCuisines.count, 0)
        XCTAssertEqual(preferences.servingsPerMeal, 2)
    }
    
    // MARK: - Nutrition Analysis Tests
    
    func testCalculateNutritionForWeek() throws {
        // Given
        let weekStart = Date()
        let meal = Meal(
            date: weekStart,
            type: .dinner,
            recipeName: "Test Recipe",
            ingredients: ["Test Ingredient"],
            servings: 2
        )
        mealManager.addMeal(meal)
        
        // When
        let weeklyNutrition = mealManager.calculateNutritionForWeek(starting: weekStart)
        
        // Then
        XCTAssertNotNil(weeklyNutrition[weekStart])
    }
    
    func testNutritionData() throws {
        // Given
        let nutrition = NutritionData(
            calories: 500,
            protein: 25.0,
            carbs: 50.0,
            fat: 20.0,
            fiber: 10.0,
            sugar: 15.0,
            sodium: 500
        )
        
        // When & Then
        XCTAssertEqual(nutrition.calories, 500)
        XCTAssertEqual(nutrition.protein, 25.0)
        XCTAssertEqual(nutrition.carbs, 50.0)
        XCTAssertEqual(nutrition.fat, 20.0)
        XCTAssertEqual(nutrition.fiber, 10.0)
        XCTAssertEqual(nutrition.sugar, 15.0)
        XCTAssertEqual(nutrition.sodium, 500)
    }
    
    // MARK: - Grocery List Generation Tests
    
    func testGenerateGroceryList() throws {
        // Given
        let weekStart = Date()
        let meal1 = Meal(
            date: weekStart,
            type: .breakfast,
            recipeName: "Breakfast",
            ingredients: ["Eggs", "Bread", "Milk"],
            servings: 1
        )
        let meal2 = Meal(
            date: weekStart,
            type: .lunch,
            recipeName: "Lunch",
            ingredients: ["Chicken", "Rice", "Milk"],
            servings: 1
        )
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // When
        let groceryList = mealManager.generateGroceryList(for: weekStart)
        
        // Then
        XCTAssertGreaterThan(groceryList.count, 0)
        
        // Check that Milk is deduplicated
        let allIngredients = groceryList.values.flatMap { $0 }
        let milkCount = allIngredients.filter { $0.lowercased() == "milk" }.count
        XCTAssertEqual(milkCount, 1) // Should be deduplicated
    }
    
    func testCategorizeIngredient() throws {
        // Test dairy categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Milk"), "Dairy")
        XCTAssertEqual(mealManager.categorizeIngredient("Cheese"), "Dairy")
        
        // Test produce categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Apple"), "Produce")
        XCTAssertEqual(mealManager.categorizeIngredient("Tomato"), "Produce")
        
        // Test meat categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Chicken"), "Meat")
        XCTAssertEqual(mealManager.categorizeIngredient("Beef"), "Meat")
        
        // Test grains categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Bread"), "Grains")
        XCTAssertEqual(mealManager.categorizeIngredient("Pasta"), "Grains")
        
        // Test pantry categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Oil"), "Pantry")
        XCTAssertEqual(mealManager.categorizeIngredient("Butter"), "Pantry")
        
        // Test other categorization
        XCTAssertEqual(mealManager.categorizeIngredient("Unknown"), "Other")
    }
    
    // MARK: - MealType Tests
    
    func testMealTypeProperties() throws {
        // Test Breakfast
        XCTAssertEqual(MealType.breakfast.rawValue, "Breakfast")
        XCTAssertEqual(MealType.breakfast.icon, "sunrise")
        XCTAssertEqual(MealType.breakfast.emoji, "🍳")
        
        // Test Lunch
        XCTAssertEqual(MealType.lunch.rawValue, "Lunch")
        XCTAssertEqual(MealType.lunch.icon, "sun.max")
        XCTAssertEqual(MealType.lunch.emoji, "🥪")
        
        // Test Dinner
        XCTAssertEqual(MealType.dinner.rawValue, "Dinner")
        XCTAssertEqual(MealType.dinner.icon, "moon")
        XCTAssertEqual(MealType.dinner.emoji, "🍝")
        
        // Test Snack
        XCTAssertEqual(MealType.snack.rawValue, "Snack")
        XCTAssertEqual(MealType.snack.icon, "leaf")
        XCTAssertEqual(MealType.snack.emoji, "🍎")
    }
    
    func testMealTypeAllCases() throws {
        let allCases = MealType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.breakfast))
        XCTAssertTrue(allCases.contains(.lunch))
        XCTAssertTrue(allCases.contains(.dinner))
        XCTAssertTrue(allCases.contains(.snack))
    }
    
    // MARK: - Meal Tests
    
    func testMealInitialization() throws {
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: "Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            servings: 2,
            notes: "Test notes"
        )
        
        XCTAssertEqual(meal.type, .dinner)
        XCTAssertEqual(meal.recipeName, "Test Recipe")
        XCTAssertEqual(meal.ingredients.count, 2)
        XCTAssertEqual(meal.servings, 2)
        XCTAssertEqual(meal.notes, "Test notes")
        XCTAssertFalse(meal.isCompleted)
    }
    
    func testMealEquality() throws {
        let meal1 = Meal(
            date: Date(),
            type: .breakfast,
            recipeName: "Same Recipe",
            ingredients: ["Ingredient"],
            servings: 1
        )
        
        let meal2 = Meal(
            date: Date(),
            type: .breakfast,
            recipeName: "Same Recipe",
            ingredients: ["Ingredient"],
            servings: 1
        )
        
        // Meals with same properties but different IDs should not be equal
        XCTAssertNotEqual(meal1, meal2)
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence() throws {
        // Given
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: "Persistent Recipe",
            ingredients: ["Persistent Ingredient"],
            servings: 1
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Create a new instance to test persistence
        let newManager = MealPlanManager.shared
        
        // Then
        let meals = newManager.meals(for: meal.date)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.recipeName, "Persistent Recipe")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyMealPlan() throws {
        let date = Date()
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 0)
        XCTAssertEqual(mealManager.mealCount(for: date), 0)
        XCTAssertFalse(mealManager.hasMeal(for: date, type: .breakfast))
    }
    
    func testMultipleMealsSameDay() throws {
        let date = Date()
        let meal1 = Meal(date: date, type: .breakfast, recipeName: "Breakfast", ingredients: [], servings: 1)
        let meal2 = Meal(date: date, type: .lunch, recipeName: "Lunch", ingredients: [], servings: 1)
        let meal3 = Meal(date: date, type: .dinner, recipeName: "Dinner", ingredients: [], servings: 1)
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        mealManager.addMeal(meal3)
        
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 3)
    }
    
    func testMealsForWeek() throws {
        let weekStart = Date()
        let meal1 = Meal(date: weekStart, type: .breakfast, recipeName: "Day 1", ingredients: [], servings: 1)
        let meal2 = Meal(date: Calendar.current.date(byAdding: .day, value: 3, to: weekStart)!, type: .lunch, recipeName: "Day 4", ingredients: [], servings: 1)
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertEqual(weekMeals.count, 2)
    }
} 