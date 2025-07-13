//
//  InventoryData.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import Combine

class InventoryManager: ObservableObject {
    @Published var inventory: [InventoryItem] = []
    
    init() {
        loadSampleInventory()
    }
    
    private func loadSampleInventory() {
        inventory = sampleGroceryItems.map { item in
            InventoryItem(
                item: item,
                currentStock: Int.random(in: 0...50),
                lowStockThreshold: 5,
                lastUpdated: Date(),
                supplier: "Main Supplier"
            )
        }
    }
    
    func checkStock(for item: GroceryItem) -> StockStatus {
        guard let inventoryItem = inventory.first(where: { $0.item.id == item.id }) else {
            return .outOfStock
        }
        
        if inventoryItem.isOutOfStock {
            return .outOfStock
        } else if inventoryItem.isLowStock {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    func findSubstitutions(for item: GroceryItem) -> [GroceryItem] {
        return sampleGroceryItems.filter { $0.category == item.category && $0.id != item.id }.prefix(3).map { $0 }
    }
    
    func getLowStockItems() -> [InventoryItem] {
        return inventory.filter { $0.isLowStock && !$0.isOutOfStock }
    }
    
    func getOutOfStockItems() -> [InventoryItem] {
        return inventory.filter { $0.isOutOfStock }
    }
    
    func updateStock(for item: GroceryItem, newStock: Int) {
        if let index = inventory.firstIndex(where: { $0.item.id == item.id }) {
            inventory[index] = InventoryItem(
                item: item,
                currentStock: newStock,
                lowStockThreshold: inventory[index].lowStockThreshold,
                lastUpdated: Date(),
                supplier: inventory[index].supplier
            )
        }
    }
} 