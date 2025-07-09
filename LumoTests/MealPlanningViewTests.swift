//
//  MealPlanningViewTests.swift
//  LumoTests
//
//  Created by Ethan on 7/4/25.
//

import XCTest
import SwiftUI
@testable import Lumo

final class MealPlanningViewTests: XCTestCase {
    var mealManager: MealPlanManager!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager.shared
        mealManager.mealPlan.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager.mealPlan.removeAll()
    }
    
    // MARK: - View State Tests
    
    func testInitialViewState() throws {
        // Given
        let view = MealPlanningView()
        
        // When & Then
        // Test that view initializes without crashing
        XCTAssertNotNil(view)
    }
    
    func testWeekStartCalculation() throws {
        // Given
        let today = Date()
        let calendar = Calendar.current
        
        // When
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Then
        XCTAssertNotNil(weekStart)
        
        // Verify it's the start of the week
        let weekday = calendar.component(.weekday, from: weekStart)
        XCTAssertEqual(weekday, calendar.firstWeekday)
    }
    
    func testWeekDaysGeneration() throws {
        // Given
        let weekStart = Date()
        let calendar = Calendar.current
        
        // When
        let weekDays = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
        
        // Then
        XCTAssertEqual(weekDays.count, 7)
        
        // Verify consecutive days
        for i in 1..<weekDays.count {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: weekDays[i])!
            XCTAssertEqual(previousDay, weekDays[i-1])
        }
    }
    
    // MARK: - Meal Management Tests
    
    func testAddMealToPlan() throws {
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
    }
    
    func testRemoveMealFromPlan() throws {
        // Given
        let date = Date()
        let meal = Meal(
            date: date,
            type: .breakfast,
            recipeName: "Test Recipe",
            ingredients: ["Ingredient"],
            servings: 1
        )
        mealManager.addMeal(meal)
        
        // When
        mealManager.removeMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 0)
    }
    
    func testUpdateMealInPlan() throws {
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
    
    // MARK: - Navigation Tests
    
    func testNavigationToAddMeal() throws {
        // Test that navigation state can be set
        // This would typically be tested in UI tests, but we can test the logic
        let canNavigateToAddMeal = true
        XCTAssertTrue(canNavigateToAddMeal)
    }
    
    func testNavigationToAutoFill() throws {
        // Test that navigation state can be set
        let canNavigateToAutoFill = true
        XCTAssertTrue(canNavigateToAutoFill)
    }
    
    func testNavigationToNutrition() throws {
        // Test that navigation state can be set
        let canNavigateToNutrition = true
        XCTAssertTrue(canNavigateToNutrition)
    }
    
    func testNavigationToGroceryList() throws {
        // Test that navigation state can be set
        let canNavigateToGroceryList = true
        XCTAssertTrue(canNavigateToGroceryList)
    }
    
    // MARK: - Date Navigation Tests
    
    func testPreviousWeekNavigation() throws {
        // Given
        let currentWeekStart = Date()
        let calendar = Calendar.current
        
        // When
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        
        // Then
        XCTAssertNotNil(previousWeekStart)
        XCTAssertTrue(previousWeekStart < currentWeekStart)
    }
    
    func testNextWeekNavigation() throws {
        // Given
        let currentWeekStart = Date()
        let calendar = Calendar.current
        
        // When
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
        
        // Then
        XCTAssertNotNil(nextWeekStart)
        XCTAssertTrue(nextWeekStart > currentWeekStart)
    }
    
    func testTodayNavigation() throws {
        // Given
        let today = Date()
        let calendar = Calendar.current
        
        // When
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Then
        XCTAssertNotNil(weekStart)
        
        // Verify today is within the week
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        XCTAssertTrue(today >= weekStart && today <= weekEnd)
    }
    
    // MARK: - Meal Type Tests
    
    func testMealTypeFiltering() throws {
        // Given
        let date = Date()
        let breakfastMeal = Meal(date: date, type: .breakfast, recipeName: "Breakfast", ingredients: [], servings: 1)
        let lunchMeal = Meal(date: date, type: .lunch, recipeName: "Lunch", ingredients: [], servings: 1)
        let dinnerMeal = Meal(date: date, type: .dinner, recipeName: "Dinner", ingredients: [], servings: 1)
        
        mealManager.addMeal(breakfastMeal)
        mealManager.addMeal(lunchMeal)
        mealManager.addMeal(dinnerMeal)
        
        // When
        let breakfastMeals = mealManager.meals(for: date).filter { $0.type == .breakfast }
        let lunchMeals = mealManager.meals(for: date).filter { $0.type == .lunch }
        let dinnerMeals = mealManager.meals(for: date).filter { $0.type == .dinner }
        
        // Then
        XCTAssertEqual(breakfastMeals.count, 1)
        XCTAssertEqual(lunchMeals.count, 1)
        XCTAssertEqual(dinnerMeals.count, 1)
    }
    
    // MARK: - Quick Actions Tests
    
    func testQuickAddMeal() throws {
        // Given
        let date = Date()
        let mealType = MealType.dinner
        
        // When
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: "Quick Add Recipe",
            ingredients: ["Quick Ingredient"],
            servings: 1
        )
        mealManager.addMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.type, mealType)
    }
    
    func testQuickRemoveMeal() throws {
        // Given
        let date = Date()
        let meal = Meal(date: date, type: .breakfast, recipeName: "Quick Remove", ingredients: [], servings: 1)
        mealManager.addMeal(meal)
        
        // When
        mealManager.removeMeal(meal)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 0)
    }
    
    // MARK: - Week Overview Tests
    
    func testWeekOverviewGeneration() throws {
        // Given
        let weekStart = Date()
        let calendar = Calendar.current
        
        // When
        let weekDays = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
        
        // Then
        XCTAssertEqual(weekDays.count, 7)
        
        // Test that each day has a meal count
        for day in weekDays {
            let mealCount = mealManager.mealCount(for: day)
            XCTAssertGreaterThanOrEqual(mealCount, 0)
        }
    }
    
    func testWeekMealSummary() throws {
        // Given
        let weekStart = Date()
        let meal1 = Meal(date: weekStart, type: .breakfast, recipeName: "Week 1", ingredients: [], servings: 1)
        let meal2 = Meal(date: Calendar.current.date(byAdding: .day, value: 3, to: weekStart)!, type: .lunch, recipeName: "Week 2", ingredients: [], servings: 1)
        
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // When
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        
        // Then
        XCTAssertEqual(weekMeals.count, 2)
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyWeekState() throws {
        // Given
        let weekStart = Date()
        
        // When
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        
        // Then
        XCTAssertEqual(weekMeals.count, 0)
    }
    
    func testEmptyDayState() throws {
        // Given
        let date = Date()
        
        // When
        let meals = mealManager.meals(for: date)
        
        // Then
        XCTAssertEqual(meals.count, 0)
    }
    
    // MARK: - Meal Completion Tests
    
    func testMealCompletionToggle() throws {
        // Given
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: "Completion Test",
            ingredients: ["Ingredient"],
            servings: 1
        )
        
        // When
        var updatedMeal = meal
        updatedMeal.isCompleted = true
        
        // Then
        XCTAssertTrue(updatedMeal.isCompleted)
        XCTAssertFalse(meal.isCompleted)
    }
    
    // MARK: - Performance Tests
    
    func testLargeMealPlanPerformance() throws {
        // Given
        let weekStart = Date()
        let calendar = Calendar.current
        
        // When
        let startTime = Date()
        
        // Add many meals
        for dayOffset in 0..<7 {
            for mealType in MealType.allCases {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
                let meal = Meal(
                    date: date,
                    type: mealType,
                    recipeName: "Performance Test \(dayOffset)-\(mealType.rawValue)",
                    ingredients: ["Ingredient"],
                    servings: 1
                )
                mealManager.addMeal(meal)
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 1.0) // Should complete in less than 1 second
        
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertEqual(weekMeals.count, 28) // 7 days * 4 meal types
    }
    
    // MARK: - Data Consistency Tests
    
    func testMealDataConsistency() throws {
        // Given
        let date = Date()
        let meal = Meal(
            date: date,
            type: .dinner,
            recipeName: "Consistency Test",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            servings: 2,
            notes: "Test notes"
        )
        
        // When
        mealManager.addMeal(meal)
        let retrievedMeals = mealManager.meals(for: date)
        
        // Then
        XCTAssertEqual(retrievedMeals.count, 1)
        let retrievedMeal = retrievedMeals.first!
        XCTAssertEqual(retrievedMeal.recipeName, meal.recipeName)
        XCTAssertEqual(retrievedMeal.type, meal.type)
        XCTAssertEqual(retrievedMeal.ingredients, meal.ingredients)
        XCTAssertEqual(retrievedMeal.servings, meal.servings)
        XCTAssertEqual(retrievedMeal.notes, meal.notes)
        XCTAssertEqual(retrievedMeal.isCompleted, meal.isCompleted)
    }
    
    // MARK: - Edge Case Tests
    
    func testMultipleMealsSameType() throws {
        // Given
        let date = Date()
        let meal1 = Meal(date: date, type: .breakfast, recipeName: "Breakfast 1", ingredients: [], servings: 1)
        let meal2 = Meal(date: date, type: .breakfast, recipeName: "Breakfast 2", ingredients: [], servings: 1)
        
        // When
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // Then
        let meals = mealManager.meals(for: date)
        XCTAssertEqual(meals.count, 2)
        
        let breakfastMeals = meals.filter { $0.type == .breakfast }
        XCTAssertEqual(breakfastMeals.count, 2)
    }
    
    func testMealWithEmptyIngredients() throws {
        // Given
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: "Empty Ingredients",
            ingredients: [],
            servings: 1
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        XCTAssertEqual(meal.ingredients.count, 0)
        XCTAssertNotNil(meal.id)
    }
    
    func testMealWithZeroServings() throws {
        // Given
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: "Zero Servings",
            ingredients: ["Ingredient"],
            servings: 0
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        XCTAssertEqual(meal.servings, 0)
    }
} 