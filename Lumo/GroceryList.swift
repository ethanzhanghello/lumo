//
//  GroceryList.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/3/25.
//

import Foundation
import SwiftUI
import UIKit // <-- Add this for haptic feedback

// MARK: - GroceryItem Model (to track quantities)
struct GroceryListItem: Identifiable, Codable, Hashable {
    var id: String { item.name + "-" + store.id.uuidString } // Unique per item-store combo
    let item: GroceryItem
    let store: Store
    var quantity: Int
    
    var totalPrice: Double {
        return item.price * Double(quantity)
    }
}

// MARK: - GroceryList Model
class GroceryList: ObservableObject {
    // Key for UserDefaults
    private let userDefaultsKey = "groceryListItems"

    @Published var groceryItems: [GroceryListItem] {
        didSet {
            // This property observer gets called every time 'groceryItems' changes
            saveToUserDefaults()
        }
    }
    
    // MARK: - Computed Properties
    var totalItems: Int {
        groceryItems.reduce(0) { $0 + $1.quantity }
    }
    
    var totalCost: Double {
        groceryItems.reduce(0) { $0 + $1.totalPrice }
    }
    
    var isEmpty: Bool {
        groceryItems.isEmpty
    }
    
    var estimatedTimeMinutes: Int {
        // Estimate 2 minutes per item for shopping
        return totalItems * 2
    }
    
    // MARK: - Initialization
    init() {
        self.groceryItems = []
        loadFromUserDefaults()
    }
    
    // MARK: - Public Methods
    func addItem(_ item: GroceryItem, store: Store, quantity: Int = 1) {
        print("addItem called for \(item.name), store: \(store.name), quantity: \(quantity)")
        if let existingIndex = groceryItems.firstIndex(where: { $0.item.id == item.id && $0.store.id == store.id }) {
            // Item already exists at this store, update quantity
            groceryItems[existingIndex].quantity += quantity
        } else {
            // Add new item-store combo
            let newItem = GroceryListItem(item: item, store: store, quantity: quantity)
            groceryItems.append(newItem)
        }
        // Haptic feedback
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func removeItem(_ item: GroceryItem, store: Store) {
        groceryItems.removeAll { $0.item.id == item.id && $0.store.id == store.id }
    }
    
    func updateQuantity(for item: GroceryItem, store: Store, to newQuantity: Int) {
        print("updateQuantity called for \(item.name) at store \(store.name) to \(newQuantity)")
        if let index = groceryItems.firstIndex(where: { $0.item.id == item.id && $0.store.id == store.id }) {
            print("Found item at index \(index), current quantity: \(groceryItems[index].quantity)")
            if newQuantity <= 0 {
                print("Removing item because new quantity is \(newQuantity)")
                groceryItems.remove(at: index)
            } else {
                print("Updating quantity from \(groceryItems[index].quantity) to \(newQuantity)")
                groceryItems[index].quantity = newQuantity
            }
        } else {
            print("Item not found in grocery list for this store")
        }
    }
    
    func clearAll() {
        groceryItems.removeAll()
    }
    
    func saveToHistory() {
        // Save current list to shopping history
        // This would integrate with a proper shopping history system
        print("Saving grocery list with \(totalItems) items to history")
    }
    
    // MARK: - Private Methods
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(groceryItems) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([GroceryListItem].self, from: data) {
            groceryItems = decoded
        }
    }
}

// MARK: - Shopping History Result
struct SaveListResult {
    let success: Bool
    let message: String
    let itemCount: Int
}
