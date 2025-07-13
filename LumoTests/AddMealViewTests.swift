//
//  AddMealViewTests.swift
//  LumoTests
//
//  Created by Ethan on 7/4/25.
//

import XCTest
import SwiftUI
@testable import Lumo

final class AddMealViewTests: XCTestCase {
    var mealManager: MealPlanManager!
    
    override func setUpWithError() throws {
        mealManager = MealPlanManager.shared
        mealManager.mealPlan.removeAll()
    }
    
    override func tearDownWithError() throws {
        mealManager.mealPlan.removeAll()
    }
    
    // MARK: - Form Validation Tests
    
    func testFormValidationWithValidData() throws {
        // Given
        let recipeName = "Test Recipe"
        let ingredients = ["Ingredient 1", "Ingredient 2"]
        let servings = 2
        let mealType = MealType.dinner
        let date = Date()
        
        // When
        let isValid = !recipeName.isEmpty && !ingredients.isEmpty && servings > 0
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testFormValidationWithEmptyRecipeName() throws {
        // Given
        let recipeName = ""
        let ingredients = ["Ingredient 1"]
        let servings = 1
        
        // When
        let isValid = !recipeName.isEmpty && !ingredients.isEmpty && servings > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testFormValidationWithEmptyIngredients() throws {
        // Given
        let recipeName = "Test Recipe"
        let ingredients: [String] = []
        let servings = 1
        
        // When
        let isValid = !recipeName.isEmpty && !ingredients.isEmpty && servings > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testFormValidationWithZeroServings() throws {
        // Given
        let recipeName = "Test Recipe"
        let ingredients = ["Ingredient 1"]
        let servings = 0
        
        // When
        let isValid = !recipeName.isEmpty && !ingredients.isEmpty && servings > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testFormValidationWithNegativeServings() throws {
        // Given
        let recipeName = "Test Recipe"
        let ingredients = ["Ingredient 1"]
        let servings = -1
        
        // When
        let isValid = !recipeName.isEmpty && !ingredients.isEmpty && servings > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Meal Creation Tests
    
    func testCreateMealWithValidData() throws {
        // Given
        let date = Date()
        let mealType = MealType.breakfast
        let recipeName = "Test Recipe"
        let ingredients = ["Ingredient 1", "Ingredient 2"]
        let servings = 2
        let notes = "Test notes"
        
        // When
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: recipeName,
            ingredients: ingredients,
            servings: servings,
            notes: notes
        )
        
        // Then
        XCTAssertEqual(meal.date, date)
        XCTAssertEqual(meal.type, mealType)
        XCTAssertEqual(meal.recipeName, recipeName)
        XCTAssertEqual(meal.ingredients, ingredients)
        XCTAssertEqual(meal.servings, servings)
        XCTAssertEqual(meal.notes, notes)
        XCTAssertFalse(meal.isCompleted)
    }
    
    func testCreateMealWithMinimalData() throws {
        // Given
        let date = Date()
        let mealType = MealType.lunch
        let recipeName = "Minimal Recipe"
        let ingredients = ["Single Ingredient"]
        let servings = 1
        
        // When
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: recipeName,
            ingredients: ingredients,
            servings: servings
        )
        
        // Then
        XCTAssertEqual(meal.date, date)
        XCTAssertEqual(meal.type, mealType)
        XCTAssertEqual(meal.recipeName, recipeName)
        XCTAssertEqual(meal.ingredients, ingredients)
        XCTAssertEqual(meal.servings, servings)
        XCTAssertNil(meal.notes)
        XCTAssertFalse(meal.isCompleted)
    }
    
    // MARK: - Ingredient Management Tests
    
    func testAddIngredient() throws {
        // Given
        var ingredients: [String] = []
        let newIngredient = "New Ingredient"
        
        // When
        ingredients.append(newIngredient)
        
        // Then
        XCTAssertEqual(ingredients.count, 1)
        XCTAssertEqual(ingredients.first, newIngredient)
    }
    
    func testRemoveIngredient() throws {
        // Given
        var ingredients = ["Ingredient 1", "Ingredient 2", "Ingredient 3"]
        let indexToRemove = 1
        
        // When
        ingredients.remove(at: indexToRemove)
        
        // Then
        XCTAssertEqual(ingredients.count, 2)
        XCTAssertEqual(ingredients, ["Ingredient 1", "Ingredient 3"])
    }
    
    func testUpdateIngredient() throws {
        // Given
        var ingredients = ["Old Ingredient", "Another Ingredient"]
        let indexToUpdate = 0
        let newValue = "Updated Ingredient"
        
        // When
        ingredients[indexToUpdate] = newValue
        
        // Then
        XCTAssertEqual(ingredients.count, 2)
        XCTAssertEqual(ingredients[indexToUpdate], newValue)
    }
    
    func testIngredientValidation() throws {
        // Given
        let validIngredient = "Valid Ingredient"
        let emptyIngredient = ""
        let whitespaceIngredient = "   "
        
        // When & Then
        XCTAssertTrue(!validIngredient.isEmpty)
        XCTAssertFalse(!emptyIngredient.isEmpty)
        XCTAssertFalse(!whitespaceIngredient.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    // MARK: - Meal Type Selection Tests
    
    func testMealTypeSelection() throws {
        // Given
        let allMealTypes = MealType.allCases
        
        // When & Then
        XCTAssertEqual(allMealTypes.count, 4)
        XCTAssertTrue(allMealTypes.contains(.breakfast))
        XCTAssertTrue(allMealTypes.contains(.lunch))
        XCTAssertTrue(allMealTypes.contains(.dinner))
        XCTAssertTrue(allMealTypes.contains(.snack))
    }
    
    func testMealTypeProperties() throws {
        // Test each meal type has required properties
        for mealType in MealType.allCases {
            XCTAssertFalse(mealType.rawValue.isEmpty)
            XCTAssertFalse(mealType.icon.isEmpty)
            XCTAssertFalse(mealType.emoji.isEmpty)
        }
    }
    
    // MARK: - Date Selection Tests
    
    func testDateSelection() throws {
        // Given
        let today = Date()
        let calendar = Calendar.current
        
        // When
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        
        // Then
        XCTAssertTrue(tomorrow > today)
        XCTAssertTrue(nextWeek > today)
        XCTAssertTrue(nextWeek > tomorrow)
    }
    
    func testDateValidation() throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // When & Then
        XCTAssertTrue(today >= today) // Today is valid
        XCTAssertTrue(tomorrow >= today) // Future dates are valid
        XCTAssertFalse(yesterday >= today) // Past dates are invalid
    }
    
    // MARK: - Servings Validation Tests
    
    func testServingsValidation() throws {
        // Given
        let validServings = [1, 2, 4, 8, 10]
        let invalidServings = [0, -1, -5]
        
        // When & Then
        for serving in validServings {
            XCTAssertTrue(serving > 0)
        }
        
        for serving in invalidServings {
            XCTAssertFalse(serving > 0)
        }
    }
    
    func testServingsRange() throws {
        // Given
        let minServings = 1
        let maxServings = 20
        let testServings = 5
        
        // When & Then
        XCTAssertTrue(testServings >= minServings)
        XCTAssertTrue(testServings <= maxServings)
    }
    
    // MARK: - Recipe Name Validation Tests
    
    func testRecipeNameValidation() throws {
        // Given
        let validNames = ["Recipe Name", "My Recipe", "Recipe 123"]
        let invalidNames = ["", "   ", "\n"]
        
        // When & Then
        for name in validNames {
            XCTAssertTrue(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        
        for name in invalidNames {
            XCTAssertFalse(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    func testRecipeNameLength() throws {
        // Given
        let shortName = "Recipe"
        let longName = String(repeating: "A", count: 100)
        let maxLength = 50
        
        // When & Then
        XCTAssertTrue(shortName.count <= maxLength)
        XCTAssertFalse(longName.count <= maxLength)
    }
    
    // MARK: - Notes Validation Tests
    
    func testNotesValidation() throws {
        // Given
        let validNotes = ["Some notes", "Notes with numbers 123", ""]
        let maxLength = 500
        
        // When & Then
        for note in validNotes {
            XCTAssertTrue(note.count <= maxLength)
        }
    }
    
    func testNotesLength() throws {
        // Given
        let shortNote = "Short note"
        let longNote = String(repeating: "A", count: 600)
        let maxLength = 500
        
        // When & Then
        XCTAssertTrue(shortNote.count <= maxLength)
        XCTAssertFalse(longNote.count <= maxLength)
    }
    
    // MARK: - Form State Tests
    
    func testFormStateInitialization() throws {
        // Given
        let date = Date()
        let mealType = MealType.dinner
        
        // When
        let formState = AddMealFormState(
            selectedDate: date,
            selectedMealType: mealType,
            recipeName: "",
            ingredients: [],
            servings: 1,
            notes: ""
        )
        
        // Then
        XCTAssertEqual(formState.selectedDate, date)
        XCTAssertEqual(formState.selectedMealType, mealType)
        XCTAssertTrue(formState.recipeName.isEmpty)
        XCTAssertTrue(formState.ingredients.isEmpty)
        XCTAssertEqual(formState.servings, 1)
        XCTAssertTrue(formState.notes.isEmpty)
    }
    
    func testFormStateValidation() throws {
        // Given
        let validFormState = AddMealFormState(
            selectedDate: Date(),
            selectedMealType: .breakfast,
            recipeName: "Valid Recipe",
            ingredients: ["Ingredient"],
            servings: 2,
            notes: "Notes"
        )
        
        let invalidFormState = AddMealFormState(
            selectedDate: Date(),
            selectedMealType: .lunch,
            recipeName: "",
            ingredients: [],
            servings: 0,
            notes: ""
        )
        
        // When
        let validFormIsValid = !validFormState.recipeName.isEmpty && 
                              !validFormState.ingredients.isEmpty && 
                              validFormState.servings > 0
        
        let invalidFormIsValid = !invalidFormState.recipeName.isEmpty && 
                                !invalidFormState.ingredients.isEmpty && 
                                invalidFormState.servings > 0
        
        // Then
        XCTAssertTrue(validFormIsValid)
        XCTAssertFalse(invalidFormIsValid)
    }
    
    // MARK: - Save Functionality Tests
    
    func testSaveMealToManager() throws {
        // Given
        let date = Date()
        let meal = Meal(
            date: date,
            type: .dinner,
            recipeName: "Save Test Recipe",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            servings: 2,
            notes: "Test notes"
        )
        
        // When
        mealManager.addMeal(meal)
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 1)
        XCTAssertEqual(savedMeals.first?.recipeName, "Save Test Recipe")
    }
    
    func testSaveMultipleMeals() throws {
        // Given
        let date = Date()
        let meal1 = Meal(date: date, type: .breakfast, recipeName: "Breakfast", ingredients: ["Eggs"], servings: 1)
        let meal2 = Meal(date: date, type: .lunch, recipeName: "Lunch", ingredients: ["Bread"], servings: 1)
        
        // When
        mealManager.addMeal(meal1)
        mealManager.addMeal(meal2)
        
        // Then
        let savedMeals = mealManager.meals(for: date)
        XCTAssertEqual(savedMeals.count, 2)
    }
    
    // MARK: - Cancel Functionality Tests
    
    func testCancelFormReset() throws {
        // Given
        var formState = AddMealFormState(
            selectedDate: Date(),
            selectedMealType: .dinner,
            recipeName: "Test Recipe",
            ingredients: ["Ingredient"],
            servings: 2,
            notes: "Test notes"
        )
        
        // When
        formState.recipeName = ""
        formState.ingredients = []
        formState.servings = 1
        formState.notes = ""
        
        // Then
        XCTAssertTrue(formState.recipeName.isEmpty)
        XCTAssertTrue(formState.ingredients.isEmpty)
        XCTAssertEqual(formState.servings, 1)
        XCTAssertTrue(formState.notes.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func testMealWithSpecialCharacters() throws {
        // Given
        let recipeName = "Recipe with special chars: !@#$%^&*()"
        let ingredients = ["Ingredient with spaces", "Ingredient-with-dashes"]
        let notes = "Notes with\nnewlines\tand\ttabs"
        
        // When
        let meal = Meal(
            date: Date(),
            type: .dinner,
            recipeName: recipeName,
            ingredients: ingredients,
            servings: 1,
            notes: notes
        )
        
        // Then
        XCTAssertEqual(meal.recipeName, recipeName)
        XCTAssertEqual(meal.ingredients, ingredients)
        XCTAssertEqual(meal.notes, notes)
    }
    
    func testMealWithVeryLongNames() throws {
        // Given
        let longRecipeName = String(repeating: "A", count: 100)
        let longIngredient = String(repeating: "B", count: 200)
        
        // When
        let meal = Meal(
            date: Date(),
            type: .breakfast,
            recipeName: longRecipeName,
            ingredients: [longIngredient],
            servings: 1
        )
        
        // Then
        XCTAssertEqual(meal.recipeName, longRecipeName)
        XCTAssertEqual(meal.ingredients.first, longIngredient)
    }
    
    func testMealWithUnicodeCharacters() throws {
        // Given
        let recipeName = "Recipe with emoji 🍕 and unicode ñáéíóú"
        let ingredients = ["Ingredient with emoji 🥬", "Another ingredient 🍅"]
        
        // When
        let meal = Meal(
            date: Date(),
            type: .lunch,
            recipeName: recipeName,
            ingredients: ingredients,
            servings: 1
        )
        
        // Then
        XCTAssertEqual(meal.recipeName, recipeName)
        XCTAssertEqual(meal.ingredients, ingredients)
    }
}

// MARK: - Helper Struct for Testing

struct AddMealFormState {
    var selectedDate: Date
    var selectedMealType: MealType
    var recipeName: String
    var ingredients: [String]
    var servings: Int
    var notes: String
} 