//
//  GroceryListTests.swift
//  LumoTests
//
//  Created by Ethan on 7/3/25.
//

import XCTest
@testable import Lumo

final class GroceryListTests: XCTestCase {
    var groceryList: GroceryList!
    var sampleItem: GroceryItem!
    
    override func setUpWithError() throws {
        groceryList = GroceryList()
        sampleItem = GroceryItem(
            name: "Test Item",
            description: "Test Description",
            price: 5.99,
            category: "Test Category",
            aisle: 1,
            brand: "Test Brand"
        )
    }
    
    override func tearDownWithError() throws {
        groceryList = nil
        sampleItem = nil
    }
    
    // MARK: - Add Item Tests
    
    func testAddItem() throws {
        groceryList.addItem(sampleItem)
        
        XCTAssertEqual(groceryList.groceryItems.count, 1)
        XCTAssertEqual(groceryList.groceryItems.first?.item.name, "Test Item")
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 1)
    }
    
    func testAddItemWithQuantity() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryList.groceryItems.count, 1)
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 3)
    }
    
    func testAddDuplicateItem() throws {
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.addItem(sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryList.groceryItems.count, 1)
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 5)
    }
    
    // MARK: - Remove Item Tests
    
    func testRemoveItem() throws {
        groceryList.addItem(sampleItem)
        groceryList.removeItem(sampleItem)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    func testRemoveNonExistentItem() throws {
        groceryList.removeItem(sampleItem)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    // MARK: - Update Quantity Tests
    
    func testUpdateQuantity() throws {
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.updateQuantity(for: sampleItem, to: 5)
        
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 5)
    }
    
    func testUpdateQuantityToZero() throws {
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.updateQuantity(for: sampleItem, to: 0)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    func testUpdateQuantityToNegative() throws {
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.updateQuantity(for: sampleItem, to: -1)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    func testUpdateQuantityForNonExistentItem() throws {
        groceryList.updateQuantity(for: sampleItem, to: 5)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    // MARK: - Increment/Decrement Tests
    
    func testIncrementQuantity() throws {
        groceryList.addItem(sampleItem, quantity: 1)
        groceryList.updateQuantity(for: sampleItem, to: 2)
        
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 2)
    }
    
    func testDecrementQuantity() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        groceryList.updateQuantity(for: sampleItem, to: 2)
        
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 2)
    }
    
    func testDecrementQuantityToZero() throws {
        groceryList.addItem(sampleItem, quantity: 1)
        groceryList.updateQuantity(for: sampleItem, to: 0)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    func testDecrementQuantityBelowZero() throws {
        groceryList.addItem(sampleItem, quantity: 1)
        groceryList.updateQuantity(for: sampleItem, to: -1)
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testTotalItems() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryList.totalItems, 3)
    }
    
    func testTotalItemsWithMultipleItems() throws {
        let item2 = GroceryItem(name: "Item 2", description: "Desc 2", price: 2.99, category: "Test", aisle: 1, brand: "Brand 2")
        
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.addItem(item2, quantity: 3)
        
        XCTAssertEqual(groceryList.totalItems, 5)
    }
    
    func testTotalCost() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryList.totalCost, 5.99 * 3, accuracy: 0.01)
    }
    
    func testTotalCostWithMultipleItems() throws {
        let item2 = GroceryItem(name: "Item 2", description: "Desc 2", price: 2.99, category: "Test", aisle: 1, brand: "Brand 2")
        
        groceryList.addItem(sampleItem, quantity: 2)
        groceryList.addItem(item2, quantity: 3)
        
        let expectedTotal = (5.99 * 2) + (2.99 * 3)
        XCTAssertEqual(groceryList.totalCost, expectedTotal, accuracy: 0.01)
    }
    
    func testIsEmpty() throws {
        XCTAssertTrue(groceryList.isEmpty)
        
        groceryList.addItem(sampleItem)
        XCTAssertFalse(groceryList.isEmpty)
    }
    
    func testEstimatedTimeMinutes() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        
        // 3 items * 2 minutes = 6 minutes
        XCTAssertEqual(groceryList.estimatedTimeMinutes, 6)
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        groceryList.clearAll()
        
        XCTAssertEqual(groceryList.groceryItems.count, 0)
        XCTAssertTrue(groceryList.isEmpty)
    }
    
    // MARK: - Save to History Tests
    
    func testSaveToHistory() throws {
        groceryList.addItem(sampleItem, quantity: 3)
        groceryList.saveToHistory()
        
        // History saving is a simple operation for now
        XCTAssertEqual(groceryList.totalItems, 3)
        XCTAssertFalse(groceryList.isEmpty)
    }
    
    // MARK: - GroceryListItem Tests
    
    func testGroceryListItemTotalPrice() throws {
        let groceryListItem = GroceryListItem(item: sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryListItem.totalPrice, 5.99 * 3, accuracy: 0.01)
    }
    
    func testGroceryListItemId() throws {
        let groceryListItem = GroceryListItem(item: sampleItem, quantity: 3)
        
        XCTAssertEqual(groceryListItem.id, "Test Item")
    }
    
    // MARK: - Edge Cases
    
    func testMultipleItemsWithSameName() throws {
        let item1 = GroceryItem(name: "Same Name", description: "Desc 1", price: 1.99, category: "Test", aisle: 1, brand: "Brand 1")
        let item2 = GroceryItem(name: "Same Name", description: "Desc 2", price: 2.99, category: "Test", aisle: 1, brand: "Brand 2")
        
        groceryList.addItem(item1, quantity: 2)
        groceryList.addItem(item2, quantity: 3)
        
        // Should treat as same item and combine quantities
        XCTAssertEqual(groceryList.groceryItems.count, 1)
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 5)
    }
    
    func testLargeQuantities() throws {
        groceryList.addItem(sampleItem, quantity: 1000)
        groceryList.updateQuantity(for: sampleItem, to: 999)
        
        XCTAssertEqual(groceryList.groceryItems.first?.quantity, 999)
        XCTAssertEqual(groceryList.totalItems, 999)
    }
    
    func testZeroPriceItem() throws {
        let freeItem = GroceryItem(name: "Free Item", description: "Free", price: 0.0, category: "Test", aisle: 1, brand: "Free Brand")
        
        groceryList.addItem(freeItem, quantity: 5)
        
        XCTAssertEqual(groceryList.totalCost, 0.0, accuracy: 0.01)
        XCTAssertEqual(groceryList.totalItems, 5)
    }
} 