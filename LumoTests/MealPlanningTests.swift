//
//  MealPlanningTests.swift
//  LumoTests
//
//  Created by Ethan on 7/11/25.
//

import XCTest
@testable import Lumo

final class MealPlanningTests: XCTestCase {
    var mealManager: MealPlanManager!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager()
        // Clear any existing data
        mealManager.mealPlan.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager = nil
    }
    
    // MARK: - Meal Deletion Tests
    
    func testMealDeletion() throws {
        // Given: A meal exists in the plan
        let testDate = Date()
        let testMeal = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Test Breakfast",
            ingredients: ["Eggs", "Bread"],
            servings: 2
        )
        
        mealManager.addMeal(testMeal)
        XCTAssertEqual(mealManager.meals(for: testDate).count, 1, "Meal should be added")
        
        // When: We delete the meal
        mealManager.removeMeal(testMeal)
        
        // Then: The meal should be removed
        XCTAssertEqual(mealManager.meals(for: testDate).count, 0, "Meal should be deleted")
    }
    
    func testMealDeletionById() throws {
        // Given: Multiple meals exist
        let testDate = Date()
        let meal1 = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Breakfast 1",
            ingredients: ["Eggs"],
            servings: 1
        )
        let meal2 = Meal(
            date: testDate,
            type: .lunch,
            recipeName: "Lunch 1",
            ingredients: ["Chicken"],
            servings: 1
        )
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        XCTAssertEqual(mealManager.meals(for: testDate).count, 2, "Two meals should be added")
        
        // When: We delete one specific meal
        mealManager.removeMeal(meal1)
        
        // Then: Only the specific meal should be removed
        let remainingMeals = mealManager.meals(for: testDate)
        XCTAssertEqual(remainingMeals.count, 1, "One meal should remain")
        XCTAssertEqual(remainingMeals.first?.recipeName, "Lunch 1", "Correct meal should remain")
    }
    
    func testMealDeletionRemovesEmptyDate() throws {
        // Given: A meal exists for a specific date
        let testDate = Date()
        let testMeal = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Test Meal",
            ingredients: ["Test"],
            servings: 1
        )
        
        mealManager.addMeal(testMeal)
        XCTAssertTrue(mealManager.mealPlan.keys.contains(Calendar.current.startOfDay(for: testDate)), "Date should exist in meal plan")
        
        // When: We delete the only meal for that date
        mealManager.removeMeal(testMeal)
        
        // Then: The date should be removed from the meal plan
        XCTAssertFalse(mealManager.mealPlan.keys.contains(Calendar.current.startOfDay(for: testDate)), "Date should be removed from meal plan")
    }
    
    // MARK: - Auto-Fill Tests
    
    func testAutoFillGeneration() throws {
        // Given: No meals exist for the week
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: [],
            maxCookingTime: 60,
            budgetPerMeal: 15.0,
            preferredCuisines: [],
            servingsPerMeal: 2
        )
        
        // When: We generate an auto-fill plan
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then: Meals should be generated
        XCTAssertGreaterThan(generatedMeals.count, 0, "Should generate some meals")
        
        // Verify meal structure
        for meal in generatedMeals {
            XCTAssertFalse(meal.recipeName.isEmpty, "Meal should have a recipe name")
            XCTAssertFalse(meal.ingredients.isEmpty, "Meal should have ingredients")
            XCTAssertGreaterThan(meal.servings, 0, "Meal should have positive servings")
        }
    }
    
    func testAutoFillRespectsPreferences() throws {
        // Given: Specific preferences
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegetarian"],
            maxCookingTime: 30,
            budgetPerMeal: 10.0,
            preferredCuisines: ["Italian"],
            servingsPerMeal: 1
        )
        
        // When: We generate an auto-fill plan
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then: Generated meals should respect preferences
        for meal in generatedMeals {
            XCTAssertEqual(meal.servings, 1, "Meal should have correct servings")
            // Note: We can't easily test recipe filtering without mocking RecipeDatabase
        }
    }
    
    func testAutoFillAppliesToMealPlan() throws {
        // Given: Auto-fill preferences and no existing meals
        let weekStart = Date()
        let preferences = AutoFillPreferences()
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // When: We add the generated meals to the meal plan
        for meal in generatedMeals {
            mealManager.addMeal(meal)
        }
        
        // Then: The meals should be in the meal plan
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertEqual(weekMeals.count, generatedMeals.count, "All generated meals should be added to meal plan")
    }
    
    // MARK: - Nutrition Analysis Tests
    
    func testNutritionCalculation() throws {
        // Given: Meals with known nutrition data
        let testDate = Date()
        let testMeal = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Test Meal",
            ingredients: ["Test"],
            servings: 2,
            recipe: Recipe(
                name: "Test Recipe",
                description: "Test",
                ingredients: [RecipeIngredient(name: "Test", amount: 1, unit: "piece", notes: nil)],
                instructions: ["Test"],
                prepTime: 10,
                cookTime: 20,
                servings: 1,
                category: .breakfast,
                cuisine: "Test",
                estimatedCost: 5.0,
                nutritionInfo: NutritionInfo(
                    calories: 300,
                    protein: 20.0,
                    carbs: 30.0,
                    fat: 10.0,
                    fiber: 5.0,
                    sugar: 5.0,
                    sodium: 500
                ),
                dietaryInfo: DietaryInfo(dietaryTags: [], allergens: []),
                tags: []
            )
        )
        
        mealManager.addMeal(testMeal)
        
        // When: We calculate nutrition for the week
        let weeklyNutrition = mealManager.calculateNutritionForWeek(starting: testDate)
        
        // Then: Nutrition should be calculated correctly
        let dayNutrition = weeklyNutrition[Calendar.current.startOfDay(for: testDate)]
        XCTAssertNotNil(dayNutrition, "Nutrition should be calculated for the day")
        
        if let nutrition = dayNutrition {
            // With 2 servings, calories should be 600 (300 * 2)
            XCTAssertEqual(nutrition.calories, 600, "Calories should be calculated correctly")
            XCTAssertEqual(nutrition.protein, 40.0, "Protein should be calculated correctly")
            XCTAssertEqual(nutrition.carbs, 60.0, "Carbs should be calculated correctly")
            XCTAssertEqual(nutrition.fat, 20.0, "Fat should be calculated correctly")
        }
    }
    
    func testNutritionCalculationWithMultipleMeals() throws {
        // Given: Multiple meals on the same day
        let testDate = Date()
        let meal1 = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Breakfast",
            ingredients: ["Test"],
            servings: 1,
            recipe: Recipe(
                name: "Breakfast",
                description: "Test",
                ingredients: [],
                instructions: [],
                prepTime: 10,
                cookTime: 10,
                servings: 1,
                category: .breakfast,
                cuisine: "Test",
                estimatedCost: 5.0,
                nutritionInfo: NutritionInfo(calories: 300, protein: 20.0, carbs: 30.0, fat: 10.0),
                dietaryInfo: DietaryInfo(dietaryTags: [], allergens: []),
                tags: []
            )
        )
        
        let meal2 = Meal(
            date: testDate,
            type: .lunch,
            recipeName: "Lunch",
            ingredients: ["Test"],
            servings: 1,
            recipe: Recipe(
                name: "Lunch",
                description: "Test",
                ingredients: [],
                instructions: [],
                prepTime: 10,
                cookTime: 10,
                servings: 1,
                category: .lunch,
                cuisine: "Test",
                estimatedCost: 5.0,
                nutritionInfo: NutritionInfo(calories: 500, protein: 30.0, carbs: 50.0, fat: 15.0),
                dietaryInfo: DietaryInfo(dietaryTags: [], allergens: []),
                tags: []
            )
        )
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // When: We calculate nutrition for the day
        let weeklyNutrition = mealManager.calculateNutritionForWeek(starting: testDate)
        let dayNutrition = weeklyNutrition[Calendar.current.startOfDay(for: testDate)]
        
        // Then: Total nutrition should be sum of both meals
        XCTAssertNotNil(dayNutrition, "Nutrition should be calculated")
        if let nutrition = dayNutrition {
            XCTAssertEqual(nutrition.calories, 800, "Total calories should be sum of both meals")
            XCTAssertEqual(nutrition.protein, 50.0, "Total protein should be sum of both meals")
            XCTAssertEqual(nutrition.carbs, 80.0, "Total carbs should be sum of both meals")
            XCTAssertEqual(nutrition.fat, 25.0, "Total fat should be sum of both meals")
        }
    }
    
    func testNutritionCalculationWithNoRecipes() throws {
        // Given: A meal without recipe data
        let testDate = Date()
        let testMeal = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Custom Meal",
            ingredients: ["Custom"],
            servings: 1
        )
        
        mealManager.addMeal(testMeal)
        
        // When: We calculate nutrition
        let weeklyNutrition = mealManager.calculateNutritionForWeek(starting: testDate)
        let dayNutrition = weeklyNutrition[Calendar.current.startOfDay(for: testDate)]
        
        // Then: Nutrition should be zero (no recipe data)
        XCTAssertNotNil(dayNutrition, "Nutrition should be calculated")
        if let nutrition = dayNutrition {
            XCTAssertEqual(nutrition.calories, 0, "Calories should be zero for meals without recipe data")
            XCTAssertEqual(nutrition.protein, 0.0, "Protein should be zero for meals without recipe data")
        }
    }
    
    // MARK: - Grocery List Generation Tests
    
    func testGroceryListGeneration() throws {
        // Given: Meals with ingredients
        let testDate = Date()
        let meal1 = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Breakfast",
            ingredients: ["Eggs", "Bread", "Milk"],
            servings: 1
        )
        let meal2 = Meal(
            date: testDate,
            type: .lunch,
            recipeName: "Lunch",
            ingredients: ["Chicken", "Lettuce", "Bread"],
            servings: 1
        )
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // When: We generate a grocery list
        let groceryList = mealManager.generateGroceryList(for: testDate)
        
        // Then: Grocery list should contain categorized ingredients
        XCTAssertGreaterThan(groceryList.count, 0, "Grocery list should not be empty")
        
        // Check that ingredients are categorized
        let allIngredients = groceryList.values.flatMap { $0 }
        XCTAssertTrue(allIngredients.contains("Eggs"), "Should contain Eggs")
        XCTAssertTrue(allIngredients.contains("Bread"), "Should contain Bread")
        XCTAssertTrue(allIngredients.contains("Chicken"), "Should contain Chicken")
        
        // Check deduplication (Bread appears in both meals)
        let breadCount = allIngredients.filter { $0 == "Bread" }.count
        XCTAssertEqual(breadCount, 1, "Bread should be deduplicated")
    }
    
    // MARK: - Integration Tests
    
    func testFullMealPlanningWorkflow() throws {
        // Given: A clean meal plan
        let weekStart = Date()
        
        // When: We generate and apply auto-fill
        let preferences = AutoFillPreferences()
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        for meal in generatedMeals {
            mealManager.addMeal(meal)
        }
        
        // Then: We should be able to delete meals
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertGreaterThan(weekMeals.count, 0, "Should have meals to delete")
        
        if let firstMeal = weekMeals.first {
            let originalCount = weekMeals.count
            mealManager.removeMeal(firstMeal)
            let newCount = mealManager.mealsForWeek(starting: weekStart).count
            XCTAssertEqual(newCount, originalCount - 1, "Meal should be deleted")
        }
        
        // And: We should be able to calculate nutrition
        let nutrition = mealManager.calculateNutritionForWeek(starting: weekStart)
        XCTAssertGreaterThan(nutrition.count, 0, "Should calculate nutrition for days with meals")
        
        // And: We should be able to generate grocery list
        let groceryList = mealManager.generateGroceryList(for: weekStart)
        XCTAssertGreaterThan(groceryList.count, 0, "Should generate grocery list")
    }
    
    func testMealPlanPersistence() throws {
        // Given: A meal in the plan
        let testDate = Date()
        let testMeal = Meal(
            date: testDate,
            type: .breakfast,
            recipeName: "Persistent Meal",
            ingredients: ["Test"],
            servings: 1
        )
        
        mealManager.addMeal(testMeal)
        XCTAssertEqual(mealManager.meals(for: testDate).count, 1, "Meal should be added")
        
        // When: We create a new meal manager instance (simulating app restart)
        let newMealManager = MealPlanManager()
        
        // Then: The meal should persist
        let persistedMeals = newMealManager.meals(for: testDate)
        XCTAssertEqual(persistedMeals.count, 1, "Meal should persist after restart")
        XCTAssertEqual(persistedMeals.first?.recipeName, "Persistent Meal", "Correct meal should persist")
    }
} 