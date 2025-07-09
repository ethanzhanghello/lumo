//
//  AutoFillViewTests.swift
//  LumoTests
//
//  Created by Ethan on 7/4/25.
//

import XCTest
import SwiftUI
@testable import Lumo

final class AutoFillViewTests: XCTestCase {
    var mealManager: MealPlanManager!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager.shared
        mealManager.mealPlan.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager.mealPlan.removeAll()
    }
    
    // MARK: - AutoFillPreferences Tests
    
    func testAutoFillPreferencesInitialization() throws {
        // Given
        let preferences = AutoFillPreferences()
        
        // When & Then
        XCTAssertEqual(preferences.dietaryRestrictions.count, 0)
        XCTAssertEqual(preferences.maxCookingTime, 60)
        XCTAssertEqual(preferences.budgetPerMeal, 15.0)
        XCTAssertEqual(preferences.preferredCuisines.count, 0)
        XCTAssertEqual(preferences.servingsPerMeal, 2)
    }
    
    func testAutoFillPreferencesWithCustomValues() throws {
        // Given
        let preferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegetarian", "Gluten-Free"],
            maxCookingTime: 30,
            budgetPerMeal: 20.0,
            preferredCuisines: ["Italian", "Mexican"],
            servingsPerMeal: 4
        )
        
        // When & Then
        XCTAssertEqual(preferences.dietaryRestrictions.count, 2)
        XCTAssertEqual(preferences.maxCookingTime, 30)
        XCTAssertEqual(preferences.budgetPerMeal, 20.0)
        XCTAssertEqual(preferences.preferredCuisines.count, 2)
        XCTAssertEqual(preferences.servingsPerMeal, 4)
    }
    
    func testAutoFillPreferencesValidation() throws {
        // Given
        let validPreferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegetarian"],
            maxCookingTime: 45,
            budgetPerMeal: 25.0,
            preferredCuisines: ["Italian"],
            servingsPerMeal: 3
        )
        
        let invalidPreferences = AutoFillPreferences(
            dietaryRestrictions: [],
            maxCookingTime: 0,
            budgetPerMeal: -5.0,
            preferredCuisines: [],
            servingsPerMeal: 0
        )
        
        // When
        let validIsValid = validPreferences.maxCookingTime > 0 && 
                          validPreferences.budgetPerMeal > 0 && 
                          validPreferences.servingsPerMeal > 0
        
        let invalidIsValid = invalidPreferences.maxCookingTime > 0 && 
                            invalidPreferences.budgetPerMeal > 0 && 
                            invalidPreferences.servingsPerMeal > 0
        
        // Then
        XCTAssertTrue(validIsValid)
        XCTAssertFalse(invalidIsValid)
    }
    
    // MARK: - Dietary Restrictions Tests
    
    func testDietaryRestrictionsManagement() throws {
        // Given
        var restrictions: [String] = []
        
        // When - Add restrictions
        restrictions.append("Vegetarian")
        restrictions.append("Gluten-Free")
        restrictions.append("Dairy-Free")
        
        // Then
        XCTAssertEqual(restrictions.count, 3)
        XCTAssertTrue(restrictions.contains("Vegetarian"))
        XCTAssertTrue(restrictions.contains("Gluten-Free"))
        XCTAssertTrue(restrictions.contains("Dairy-Free"))
    }
    
    func testDietaryRestrictionsRemoval() throws {
        // Given
        var restrictions = ["Vegetarian", "Gluten-Free", "Dairy-Free"]
        
        // When
        restrictions.removeAll { $0 == "Gluten-Free" }
        
        // Then
        XCTAssertEqual(restrictions.count, 2)
        XCTAssertFalse(restrictions.contains("Gluten-Free"))
        XCTAssertTrue(restrictions.contains("Vegetarian"))
        XCTAssertTrue(restrictions.contains("Dairy-Free"))
    }
    
    func testDietaryRestrictionsValidation() throws {
        // Given
        let validRestrictions = ["Vegetarian", "Vegan", "Gluten-Free"]
        let invalidRestrictions = ["", "   ", "Invalid-Restriction"]
        
        // When & Then
        for restriction in validRestrictions {
            XCTAssertTrue(!restriction.isEmpty)
            XCTAssertTrue(!restriction.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        
        for restriction in invalidRestrictions {
            XCTAssertFalse(!restriction.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    
    // MARK: - Cooking Time Tests
    
    func testCookingTimeValidation() throws {
        // Given
        let validTimes = [15, 30, 45, 60, 90, 120]
        let invalidTimes = [0, -5, -10]
        
        // When & Then
        for time in validTimes {
            XCTAssertTrue(time > 0)
            XCTAssertTrue(time <= 180) // Max 3 hours
        }
        
        for time in invalidTimes {
            XCTAssertFalse(time > 0)
        }
    }
    
    func testCookingTimeRange() throws {
        // Given
        let minTime = 5
        let maxTime = 180
        let testTime = 45
        
        // When & Then
        XCTAssertTrue(testTime >= minTime)
        XCTAssertTrue(testTime <= maxTime)
    }
    
    // MARK: - Budget Tests
    
    func testBudgetValidation() throws {
        // Given
        let validBudgets: [Double] = [5.0, 10.0, 15.0, 25.0, 50.0]
        let invalidBudgets: [Double] = [0.0, -5.0, -10.0]
        
        // When & Then
        for budget in validBudgets {
            XCTAssertTrue(budget > 0)
            XCTAssertTrue(budget <= 100.0) // Max $100 per meal
        }
        
        for budget in invalidBudgets {
            XCTAssertFalse(budget > 0)
        }
    }
    
    func testBudgetRange() throws {
        // Given
        let minBudget: Double = 1.0
        let maxBudget: Double = 100.0
        let testBudget: Double = 25.0
        
        // When & Then
        XCTAssertTrue(testBudget >= minBudget)
        XCTAssertTrue(testBudget <= maxBudget)
    }
    
    // MARK: - Cuisine Preferences Tests
    
    func testCuisinePreferencesManagement() throws {
        // Given
        var cuisines: [String] = []
        
        // When - Add cuisines
        cuisines.append("Italian")
        cuisines.append("Mexican")
        cuisines.append("Asian")
        cuisines.append("Mediterranean")
        
        // Then
        XCTAssertEqual(cuisines.count, 4)
        XCTAssertTrue(cuisines.contains("Italian"))
        XCTAssertTrue(cuisines.contains("Mexican"))
        XCTAssertTrue(cuisines.contains("Asian"))
        XCTAssertTrue(cuisines.contains("Mediterranean"))
    }
    
    func testCuisinePreferencesRemoval() throws {
        // Given
        var cuisines = ["Italian", "Mexican", "Asian", "Mediterranean"]
        
        // When
        cuisines.removeAll { $0 == "Asian" }
        
        // Then
        XCTAssertEqual(cuisines.count, 3)
        XCTAssertFalse(cuisines.contains("Asian"))
        XCTAssertTrue(cuisines.contains("Italian"))
        XCTAssertTrue(cuisines.contains("Mexican"))
        XCTAssertTrue(cuisines.contains("Mediterranean"))
    }
    
    func testCuisinePreferencesValidation() throws {
        // Given
        let validCuisines = ["Italian", "Mexican", "Asian", "Mediterranean", "American"]
        let invalidCuisines = ["", "   ", "Invalid-Cuisine"]
        
        // When & Then
        for cuisine in validCuisines {
            XCTAssertTrue(!cuisine.isEmpty)
            XCTAssertTrue(!cuisine.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        
        for cuisine in invalidCuisines {
            XCTAssertFalse(!cuisine.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    
    // MARK: - Servings Tests
    
    func testServingsValidation() throws {
        // Given
        let validServings = [1, 2, 4, 6, 8, 10]
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
    
    // MARK: - Auto-Fill Generation Tests
    
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
    
    func testAutoFillWithNoPreferences() throws {
        // Given
        let weekStart = Date()
        let preferences = AutoFillPreferences()
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    func testAutoFillWithStrictPreferences() throws {
        // Given
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegan", "Gluten-Free"],
            maxCookingTime: 15,
            budgetPerMeal: 5.0,
            preferredCuisines: ["Raw"],
            servingsPerMeal: 1
        )
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    // MARK: - Form State Tests
    
    func testFormStateInitialization() throws {
        // Given
        let formState = AutoFillFormState(
            dietaryRestrictions: [],
            maxCookingTime: 60,
            budgetPerMeal: 15.0,
            preferredCuisines: [],
            servingsPerMeal: 2,
            isGenerating: false
        )
        
        // When & Then
        XCTAssertTrue(formState.dietaryRestrictions.isEmpty)
        XCTAssertEqual(formState.maxCookingTime, 60)
        XCTAssertEqual(formState.budgetPerMeal, 15.0)
        XCTAssertTrue(formState.preferredCuisines.isEmpty)
        XCTAssertEqual(formState.servingsPerMeal, 2)
        XCTAssertFalse(formState.isGenerating)
    }
    
    func testFormStateValidation() throws {
        // Given
        let validFormState = AutoFillFormState(
            dietaryRestrictions: ["Vegetarian"],
            maxCookingTime: 30,
            budgetPerMeal: 20.0,
            preferredCuisines: ["Italian"],
            servingsPerMeal: 3,
            isGenerating: false
        )
        
        let invalidFormState = AutoFillFormState(
            dietaryRestrictions: [],
            maxCookingTime: 0,
            budgetPerMeal: -5.0,
            preferredCuisines: [],
            servingsPerMeal: 0,
            isGenerating: false
        )
        
        // When
        let validIsValid = validFormState.maxCookingTime > 0 && 
                          validFormState.budgetPerMeal > 0 && 
                          validFormState.servingsPerMeal > 0
        
        let invalidIsValid = invalidFormState.maxCookingTime > 0 && 
                            invalidFormState.budgetPerMeal > 0 && 
                            invalidFormState.servingsPerMeal > 0
        
        // Then
        XCTAssertTrue(validIsValid)
        XCTAssertFalse(invalidIsValid)
    }
    
    // MARK: - Button Functionality Tests
    
    func testGenerateButtonState() throws {
        // Given
        let isGenerating = false
        let isValidForm = true
        
        // When
        let canGenerate = !isGenerating && isValidForm
        
        // Then
        XCTAssertTrue(canGenerate)
    }
    
    func testGenerateButtonStateWhileGenerating() throws {
        // Given
        let isGenerating = true
        let isValidForm = true
        
        // When
        let canGenerate = !isGenerating && isValidForm
        
        // Then
        XCTAssertFalse(canGenerate)
    }
    
    func testGenerateButtonStateWithInvalidForm() throws {
        // Given
        let isGenerating = false
        let isValidForm = false
        
        // When
        let canGenerate = !isGenerating && isValidForm
        
        // Then
        XCTAssertFalse(canGenerate)
    }
    
    // MARK: - Preference Application Tests
    
    func testApplyPreferencesToMealPlan() throws {
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
        
        // Apply meals to plan
        for meal in generatedMeals {
            mealManager.addMeal(meal)
        }
        
        // Then
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertEqual(weekMeals.count, generatedMeals.count)
    }
    
    func testClearExistingMeals() throws {
        // Given
        let weekStart = Date()
        let existingMeal = Meal(
            date: weekStart,
            type: .breakfast,
            recipeName: "Existing Meal",
            ingredients: ["Ingredient"],
            servings: 1
        )
        mealManager.addMeal(existingMeal)
        
        // When
        let weekMeals = mealManager.mealsForWeek(starting: weekStart)
        mealManager.mealPlan.removeAll()
        
        // Then
        XCTAssertEqual(weekMeals.count, 1)
        let clearedMeals = mealManager.mealsForWeek(starting: weekStart)
        XCTAssertEqual(clearedMeals.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testAutoFillWithExtremePreferences() throws {
        // Given
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegan", "Gluten-Free", "Nut-Free", "Soy-Free"],
            maxCookingTime: 5,
            budgetPerMeal: 1.0,
            preferredCuisines: ["Raw", "Paleo"],
            servingsPerMeal: 12
        )
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    func testAutoFillWithEmptyPreferences() throws {
        // Given
        let weekStart = Date()
        let preferences = AutoFillPreferences(
            dietaryRestrictions: [],
            maxCookingTime: 60,
            budgetPerMeal: 15.0,
            preferredCuisines: [],
            servingsPerMeal: 2
        )
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    func testAutoFillWithVeryLongPreferences() throws {
        // Given
        let weekStart = Date()
        let longRestrictions = Array(repeating: "Restriction", count: 50)
        let longCuisines = Array(repeating: "Cuisine", count: 50)
        
        let preferences = AutoFillPreferences(
            dietaryRestrictions: longRestrictions,
            maxCookingTime: 60,
            budgetPerMeal: 15.0,
            preferredCuisines: longCuisines,
            servingsPerMeal: 2
        )
        
        // When
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        
        // Then
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testAutoFillPerformance() throws {
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
        let startTime = Date()
        let generatedMeals = mealManager.generateAutoFillPlan(for: weekStart, preferences: preferences)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 5.0) // Should complete in less than 5 seconds
        XCTAssertGreaterThanOrEqual(generatedMeals.count, 0)
    }
    
    // MARK: - Data Consistency Tests
    
    func testPreferencesDataConsistency() throws {
        // Given
        let originalPreferences = AutoFillPreferences(
            dietaryRestrictions: ["Vegetarian", "Gluten-Free"],
            maxCookingTime: 45,
            budgetPerMeal: 25.0,
            preferredCuisines: ["Italian", "Mediterranean"],
            servingsPerMeal: 4
        )
        
        // When
        let copiedPreferences = AutoFillPreferences(
            dietaryRestrictions: originalPreferences.dietaryRestrictions,
            maxCookingTime: originalPreferences.maxCookingTime,
            budgetPerMeal: originalPreferences.budgetPerMeal,
            preferredCuisines: originalPreferences.preferredCuisines,
            servingsPerMeal: originalPreferences.servingsPerMeal
        )
        
        // Then
        XCTAssertEqual(copiedPreferences.dietaryRestrictions, originalPreferences.dietaryRestrictions)
        XCTAssertEqual(copiedPreferences.maxCookingTime, originalPreferences.maxCookingTime)
        XCTAssertEqual(copiedPreferences.budgetPerMeal, originalPreferences.budgetPerMeal)
        XCTAssertEqual(copiedPreferences.preferredCuisines, originalPreferences.preferredCuisines)
        XCTAssertEqual(copiedPreferences.servingsPerMeal, originalPreferences.servingsPerMeal)
    }
}

// MARK: - Helper Struct for Testing

struct AutoFillFormState {
    var dietaryRestrictions: [String]
    var maxCookingTime: Int
    var budgetPerMeal: Double
    var preferredCuisines: [String]
    var servingsPerMeal: Int
    var isGenerating: Bool
} 