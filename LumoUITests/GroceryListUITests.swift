//
//  GroceryListUITests.swift
//  LumoUITests
//
//  Created by Ethan on 7/3/25.
//

import XCTest

final class GroceryListUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testGroceryListIncrementDecrement() throws {
        // Navigate to grocery list
        let groceryListTab = app.tabBars.buttons["Grocery List"]
        XCTAssertTrue(groceryListTab.exists)
        groceryListTab.tap()
        
        // Wait for grocery list to load
        let groceryListTitle = app.staticTexts["Grocery List"]
        XCTAssertTrue(groceryListTitle.waitForExistence(timeout: 5))
        
        // Add an item to test with
        let searchField = app.textFields["Search or add items..."]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("Milk")
        
        // Submit search
        app.keyboards.buttons["Search"].tap()
        
        // Wait for item to appear
        let milkItem = app.staticTexts["Milk"]
        XCTAssertTrue(milkItem.waitForExistence(timeout: 5))
        
        // Find the quantity controls
        let plusButton = app.buttons["plus.circle.fill"].firstMatch
        let minusButton = app.buttons["minus.circle.fill"].firstMatch
        
        XCTAssertTrue(plusButton.exists)
        XCTAssertTrue(minusButton.exists)
        
        // Test increment
        let initialQuantity = app.staticTexts["1"]
        XCTAssertTrue(initialQuantity.exists)
        
        plusButton.tap()
        
        // Wait for quantity to update
        let updatedQuantity = app.staticTexts["2"]
        XCTAssertTrue(updatedQuantity.waitForExistence(timeout: 2))
        
        // Test decrement
        minusButton.tap()
        
        // Wait for quantity to go back to 1
        XCTAssertTrue(initialQuantity.waitForExistence(timeout: 2))
        
        // Test that minus button is disabled when quantity is 1
        minusButton.tap()
        XCTAssertTrue(initialQuantity.exists) // Should still be 1
    }
    
    func testGroceryListItemDetailTap() throws {
        // Navigate to grocery list
        let groceryListTab = app.tabBars.buttons["Grocery List"]
        XCTAssertTrue(groceryListTab.exists)
        groceryListTab.tap()
        
        // Wait for grocery list to load
        let groceryListTitle = app.staticTexts["Grocery List"]
        XCTAssertTrue(groceryListTitle.waitForExistence(timeout: 5))
        
        // Add an item to test with
        let searchField = app.textFields["Search or add items..."]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("Bread")
        
        // Submit search
        app.keyboards.buttons["Search"].tap()
        
        // Wait for item to appear
        let breadItem = app.staticTexts["Bread"]
        XCTAssertTrue(breadItem.waitForExistence(timeout: 5))
        
        // Tap on the item details (not the quantity controls)
        breadItem.tap()
        
        // Should show item detail view
        let detailView = app.navigationBars.firstMatch
        XCTAssertTrue(detailView.waitForExistence(timeout: 2))
    }
    
    func testGroceryListQuantityControlsDontTriggerDetail() throws {
        // Navigate to grocery list
        let groceryListTab = app.tabBars.buttons["Grocery List"]
        XCTAssertTrue(groceryListTab.exists)
        groceryListTab.tap()
        
        // Wait for grocery list to load
        let groceryListTitle = app.staticTexts["Grocery List"]
        XCTAssertTrue(groceryListTitle.waitForExistence(timeout: 5))
        
        // Add an item to test with
        let searchField = app.textFields["Search or add items..."]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("Eggs")
        
        // Submit search
        app.keyboards.buttons["Search"].tap()
        
        // Wait for item to appear
        let eggsItem = app.staticTexts["Eggs"]
        XCTAssertTrue(eggsItem.waitForExistence(timeout: 5))
        
        // Find the quantity controls
        let plusButton = app.buttons["plus.circle.fill"].firstMatch
        let minusButton = app.buttons["minus.circle.fill"].firstMatch
        
        XCTAssertTrue(plusButton.exists)
        XCTAssertTrue(minusButton.exists)
        
        // Tap plus button
        plusButton.tap()
        
        // Should not show item detail view
        let detailView = app.navigationBars.firstMatch
        XCTAssertFalse(detailView.exists)
        
        // Quantity should have increased
        let updatedQuantity = app.staticTexts["2"]
        XCTAssertTrue(updatedQuantity.waitForExistence(timeout: 2))
    }
} 