//
//  ShoppingCart.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
import SwiftUI

// MARK: - CartItem Model (to track quantities)
struct CartItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let item: GroceryItem
    var quantity: Int
    
    var totalPrice: Double {
        return item.price * Double(quantity)
    }
}

// MARK: - ShoppingCart Model
class ShoppingCart: ObservableObject {
    // Key for UserDefaults
    private let userDefaultsKey = "shoppingCartItems"

    @Published var cartItems: [CartItem] {
        didSet {
            // This property observer gets called every time 'cartItems' changes.
            // When it changes, we save the new state to UserDefaults.
            if let encoded = try? JSONEncoder().encode(cartItems) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
                print("Shopping cart items saved to UserDefaults. Total items: \(cartItems.count)")
            } else {
                print("Failed to encode shopping cart items for saving.")
            }
        }
    }

    init() {
        if let savedItemsData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedItems = try? JSONDecoder().decode([CartItem].self, from: savedItemsData) {
                self.cartItems = decodedItems
                print("Shopping cart items loaded from UserDefaults. Total items: \(cartItems.count)")
                return // Exit init if successful
            } else {
                print("Failed to decode saved shopping cart items.")
            }
        }
        self.cartItems = [] // Fallback if no saved items
        print("Shopping cart initialized with empty list (no saved items or decoding error).")
    }

    // MARK: - Item Management Functions
    
    func addItem(_ item: GroceryItem, quantity: Int = 1) {
        if let existingIndex = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            // Item already exists, increase quantity
            cartItems[existingIndex].quantity += quantity
            print("Updated quantity for \(item.name) to \(cartItems[existingIndex].quantity)")
        } else {
            // Item doesn't exist, add new cart item
            let newCartItem = CartItem(item: item, quantity: quantity)
            cartItems.append(newCartItem)
            print("Added new item: \(item.name) with quantity \(quantity)")
        }
    }

    func removeItem(_ item: GroceryItem) {
        if let index = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            cartItems.remove(at: index)
            print("Removed item: \(item.name)")
        } else {
            print("Item \(item.name) not found in cart.")
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

    func removeItems(at offsets: IndexSet) {
        cartItems.remove(atOffsets: offsets)
        print("Removed items at offsets. Total items: \(cartItems.count)")
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        cartItems.move(fromOffsets: source, toOffset: destination)
        print("Moved items. Total items: \(cartItems.count)")
    }

    func clearCart() {
        cartItems.removeAll()
        print("Cart cleared.")
    }

    // MARK: - Computed Properties
    
    var totalCost: Double {
        cartItems.reduce(0) { $0 + $1.totalPrice }
    }

    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var estimatedTimeMinutes: Int {
        if cartItems.isEmpty { return 0 }
        return 5 + (totalItems / 3) + (totalItems % 3 == 0 ? 0 : 1)
    }

    var isEmpty: Bool {
        return cartItems.isEmpty
    }

    // MARK: - Checkout Functions
    
    func checkout() -> CheckoutResult {
        guard !cartItems.isEmpty else {
            return CheckoutResult(success: false, message: "Cart is empty", order: nil)
        }
        
        // Simulate checkout process
        let orderNumber = generateOrderNumber()
        let order = Order(
            id: orderNumber,
            items: cartItems,
            totalCost: totalCost,
            estimatedTime: estimatedTimeMinutes,
            timestamp: Date()
        )
        
        // Clear cart after successful checkout
        clearCart()
        
        return CheckoutResult(success: true, message: "Order #\(orderNumber) placed successfully!", order: order)
    }
    
    private func generateOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "LUMO-\(formatter.string(from: Date()))"
    }
}

// MARK: - Supporting Models

struct CheckoutResult {
    let success: Bool
    let message: String
    let order: Order?
}

struct Order: Identifiable, Codable {
    let id: String
    let items: [CartItem]
    let totalCost: Double
    let estimatedTime: Int
    let timestamp: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
