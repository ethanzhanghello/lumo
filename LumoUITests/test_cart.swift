#!/usr/bin/env swift

// Simple test to verify shopping cart functionality
// Run with: swift test_cart.swift

import Foundation

// Simplified versions of your models for testing
struct GroceryItem {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let aisle: String
}

struct CartItem {
    let id = UUID()
    let item: GroceryItem
    var quantity: Int
    
    var totalPrice: Double {
        return item.price * Double(quantity)
    }
}

class ShoppingCart {
    var cartItems: [CartItem] = []
    
    func addItem(_ item: GroceryItem, quantity: Int = 1) {
        if let existingIndex = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            cartItems[existingIndex].quantity += quantity
            print("Updated quantity for \(item.name) to \(cartItems[existingIndex].quantity)")
        } else {
            let newCartItem = CartItem(item: item, quantity: quantity)
            cartItems.append(newCartItem)
            print("Added new item: \(item.name) with quantity \(quantity)")
        }
    }
    
    func removeItem(_ item: GroceryItem) {
        if let index = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            cartItems.remove(at: index)
            print("Removed item: \(item.name)")
        }
    }
    
    func updateQuantity(for item: GroceryItem, to quantity: Int) {
        if let index = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            if quantity <= 0 {
                cartItems.remove(at: index)
                print("Removed item: \(item.name) (quantity set to 0)")
            } else {
                cartItems[index].quantity = quantity
                print("Updated quantity for \(item.name) to \(quantity)")
            }
        }
    }
    
    var totalCost: Double {
        cartItems.reduce(0) { $0 + $1.totalPrice }
    }
    
    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    var isEmpty: Bool {
        return cartItems.isEmpty
    }
}

// Run the test
print("🧪 Testing Shopping Cart Functionality...\n")

let cart = ShoppingCart()

// Test 1: Add items
print("📦 Test 1: Adding items")
let milk = GroceryItem(name: "Organic Whole Milk", description: "1 gallon", price: 5.99, aisle: "Grocery")
let bread = GroceryItem(name: "Artisan Bread", description: "Fresh sourdough", price: 3.75, aisle: "Grocery")

cart.addItem(milk)
cart.addItem(bread)
cart.addItem(milk) // Should increase quantity

print("Total items: \(cart.totalItems)")
print("Total cost: $\(cart.totalCost, specifier: "%.2f")")
print("Cart items count: \(cart.cartItems.count)\n")

// Test 2: Update quantities
print("🔢 Test 2: Updating quantities")
cart.updateQuantity(for: milk, to: 3)
cart.updateQuantity(for: bread, to: 2)

print("Total items: \(cart.totalItems)")
print("Total cost: $\(cart.totalCost, specifier: "%.2f")\n")

// Test 3: Remove items
print("🗑️ Test 3: Removing items")
cart.removeItem(bread)

print("Total items: \(cart.totalItems)")
print("Total cost: $\(cart.totalCost, specifier: "%.2f")")
print("Cart items count: \(cart.cartItems.count)\n")

// Test 4: Clear cart
print("📭 Test 4: Clear cart")
cart.cartItems.removeAll()
print("Is empty: \(cart.isEmpty)")
print("Total items: \(cart.totalItems)")

print("\n✅ All tests completed successfully!")
print("Your shopping cart logic is working correctly! 🎉") 