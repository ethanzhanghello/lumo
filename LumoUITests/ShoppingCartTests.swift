//
//  ShoppingCartTests.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation

// Simple test functions to verify shopping cart functionality
class ShoppingCartTests {
    
    static func runTests() {
        print("🧪 Running Shopping Cart Tests...")
        
        let cart = ShoppingCart()
        
        // Test 1: Add items
        print("\n📦 Test 1: Adding items")
        let milk = GroceryItem(name: "Milk", description: "Fresh milk", price: 3.99, aisle: "Dairy")
        let bread = GroceryItem(name: "Bread", description: "Fresh bread", price: 2.49, aisle: "Bakery")
        
        cart.addItem(milk)
        cart.addItem(bread)
        cart.addItem(milk) // Should increase quantity
        
        print("Total items: \(cart.totalItems)")
        print("Total cost: $\(cart.totalCost, specifier: "%.2f")")
        print("Cart items count: \(cart.cartItems.count)")
        
        // Test 2: Update quantities
        print("\n🔢 Test 2: Updating quantities")
        cart.updateQuantity(for: milk, to: 3)
        cart.updateQuantity(for: bread, to: 2)
        
        print("Total items: \(cart.totalItems)")
        print("Total cost: $\(cart.totalCost, specifier: "%.2f")")
        
        // Test 3: Remove items
        print("\n🗑️ Test 3: Removing items")
        cart.removeItem(bread)
        
        print("Total items: \(cart.totalItems)")
        print("Total cost: $\(cart.totalCost, specifier: "%.2f")")
        print("Cart items count: \(cart.cartItems.count)")
        
        // Test 4: Checkout
        print("\n💳 Test 4: Checkout")
        let result = cart.checkout()
        print("Checkout success: \(result.success)")
        print("Message: \(result.message)")
        
        // Test 5: Empty cart
        print("\n📭 Test 5: Empty cart")
        print("Is empty: \(cart.isEmpty)")
        print("Total items: \(cart.totalItems)")
        
        print("\n✅ All tests completed!")
    }
}

// Uncomment the line below to run tests when the app starts
// ShoppingCartTests.runTests() 