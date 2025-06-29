//
//  ShoppingCart.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
import SwiftUI // Not strictly needed for ShoppingCart logic, but often used with ObservableObject

// MARK: - ShoppingCart Model
class ShoppingCart: ObservableObject {
    // Key for UserDefaults
    private let userDefaultsKey = "shoppingCartItems"

    @Published var items: [GroceryItem] {
        didSet {
            // This property observer gets called every time 'items' changes.
            // When it changes, we save the new state to UserDefaults.
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
                print("Shopping cart items saved to UserDefaults. Total items: \(items.count)")
            } else {
                print("Failed to encode shopping cart items for saving.")
            }
        }
    }

    init() {
        if let savedItemsData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedItems = try? JSONDecoder().decode([GroceryItem].self, from: savedItemsData) {
                self.items = decodedItems
                print("Shopping cart items loaded from UserDefaults. Total items: \(items.count)")
                return // Exit init if successful
            } else {
                print("Failed to decode saved shopping cart items.")
            }
        }
        self.items = [] // Fallback if no saved items
        print("Shopping cart initialized with empty list (no saved items or decoding error).")
    }


    func addItem(_ item: GroceryItem) {
        // Only add if the item (by ID) is not already in the cart
        // This prevents duplicate entries for the same conceptual item.
        if !items.contains(where: { $0.id == item.id }) {
            items.append(item)
            print("Added item: \(item.name). Total items: \(items.count)")
        } else {
            print("Item \(item.name) (ID: \(item.id)) is already in the cart. Not adding duplicate.")
        }
    }

    // MARK: - New removeItem function
    func removeItem(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            print("Removed item: \(item.name). Total items: \(items.count)")
        } else {
            print("Item \(item.name) (ID: \(item.id)) not found in cart.")
        }
    }

    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        // The didSet observer for `items` will handle saving to UserDefaults.
        print("Removed items at offsets. Total items: \(items.count)")
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        // The didSet observer for `items` will handle saving to UserDefaults.
        print("Moved items. Total items: \(items.count)")
    }

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("Shopping cart items saved to UserDefaults. Total items: \(items.count)")
        } else {
            print("Failed to encode shopping cart items for saving.")
        }
    }


    func clearCart() {
        items.removeAll()
        print("Cart cleared.")
    }

    var totalCost: Double {
        items.reduce(0) { $0 + $1.price }
    }

    var estimatedTimeMinutes: Int {
        if items.isEmpty { return 0 }
        return 5 + (items.count / 3) + (items.count % 3 == 0 ? 0 : 1)
    }
}
