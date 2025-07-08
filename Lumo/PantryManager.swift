//
//  PantryManager.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import Combine

class PantryManager: ObservableObject {
    @Published var pantryItems: [PantryItem] = []
    
    init() {
        loadSamplePantry()
    }
    
    private func loadSamplePantry() {
        let sampleItems = [
            (sampleGroceryItems[0], 2, Calendar.current.date(byAdding: .day, value: 3, to: Date())),
            (sampleGroceryItems[3], 1, Calendar.current.date(byAdding: .day, value: 7, to: Date())),
            (sampleGroceryItems[8], 1, Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        ]
        
        pantryItems = sampleItems.map { item, quantity, expiration in
            PantryItem(
                item: item,
                quantity: quantity,
                expirationDate: expiration,
                dateAdded: Date(),
                notes: nil
            )
        }
    }
    
    func addItem(_ item: GroceryItem, quantity: Int = 1, expirationDate: Date? = nil) {
        if let existingIndex = pantryItems.firstIndex(where: { $0.item.id == item.id }) {
            pantryItems[existingIndex] = PantryItem(
                item: item,
                quantity: pantryItems[existingIndex].quantity + quantity,
                expirationDate: expirationDate ?? pantryItems[existingIndex].expirationDate,
                dateAdded: pantryItems[existingIndex].dateAdded,
                notes: pantryItems[existingIndex].notes
            )
        } else {
            let newItem = PantryItem(
                item: item,
                quantity: quantity,
                expirationDate: expirationDate,
                dateAdded: Date(),
                notes: nil
            )
            pantryItems.append(newItem)
        }
    }
    
    func removeItem(_ item: GroceryItem) {
        pantryItems.removeAll { $0.item.id == item.id }
    }
    
    func getExpiringItems(within days: Int = 7) -> [PantryItem] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return pantryItems.filter { item in
            guard let expirationDate = item.expirationDate else { return false }
            return expirationDate <= cutoffDate && !item.isExpired
        }
    }
    
    func getExpiredItems() -> [PantryItem] {
        return pantryItems.filter { $0.isExpired }
    }
    
    func checkPantry(for items: [GroceryItem]) -> PantryCheckResult {
        var itemsToRemove: [GroceryItem] = []
        var itemsToKeep: [GroceryItem] = []
        var missingEssentials: [GroceryItem] = []
        
        for item in items {
            if let pantryItem = pantryItems.first(where: { $0.item.id == item.id }) {
                if pantryItem.quantity > 0 && !pantryItem.isExpired {
                    itemsToRemove.append(item)
                } else {
                    itemsToKeep.append(item)
                }
            } else {
                itemsToKeep.append(item)
            }
        }
        
        // Check for missing essentials
        let essentialItems = sampleGroceryItems.filter { $0.category == "Pantry" || $0.category == "Dairy" }
        for essential in essentialItems {
            if !pantryItems.contains(where: { $0.item.id == essential.id }) {
                missingEssentials.append(essential)
            }
        }
        
        return PantryCheckResult(
            itemsToRemove: itemsToRemove,
            itemsToKeep: itemsToKeep,
            missingEssentials: missingEssentials
        )
    }
}

struct PantryCheckResult {
    let itemsToRemove: [GroceryItem]
    let itemsToKeep: [GroceryItem]
    let missingEssentials: [GroceryItem]
    
    var hasItemsToRemove: Bool {
        return !itemsToRemove.isEmpty
    }
    
    var hasMissingEssentials: Bool {
        return !missingEssentials.isEmpty
    }
} 