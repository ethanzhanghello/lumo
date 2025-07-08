//
//  BudgetManager.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import Combine

class BudgetManager: ObservableObject {
    @Published var budgetItems: [GroceryItem] = []
    @Published var totalBudget: Double = 100.0
    @Published var spentAmount: Double = 0.0
    
    init() {
        loadSampleBudget()
    }
    
    private func loadSampleBudget() {
        budgetItems = sampleGroceryItems.prefix(5).map { $0 }
        spentAmount = budgetItems.reduce(0) { $0 + $1.price }
    }
    
    func estimateTotalCost(for items: [GroceryItem]) -> CostEstimate {
        let totalCost = items.reduce(0) { $0 + $1.price }
        let savingsAmount = items.filter { $0.hasDeal }.reduce(0) { $0 + ($1.price * 0.2) } // Assume 20% savings on deals
        let breakdown = Dictionary(grouping: items, by: { $0.category })
            .mapValues { items in items.reduce(0) { $0 + $1.price } }
        
        return CostEstimate(
            totalCost: totalCost,
            savingsAmount: savingsAmount,
            breakdown: breakdown
        )
    }
    
    func estimateMealPlanCost(for recipes: [Recipe]) -> CostEstimate {
        let allIngredients = recipes.flatMap { $0.ingredients }
        let ingredientItems = allIngredients.compactMap { ingredient in
            sampleGroceryItems.first { $0.name.lowercased() == ingredient.name.lowercased() }
        }
        
        return estimateTotalCost(for: ingredientItems)
    }
    
    func optimizeBudgetForTarget(targetBudget: Double, items: [GroceryItem]) -> BudgetOptimizationResult {
        let sortedItems = items.sorted { $0.price < $1.price }
        var optimizedItems: [GroceryItem] = []
        var currentCost: Double = 0
        
        for item in sortedItems {
            if currentCost + item.price <= targetBudget {
                optimizedItems.append(item)
                currentCost += item.price
            }
        }
        
        let originalCost = items.reduce(0) { $0 + $1.price }
        let savings = originalCost - currentCost
        
        let recommendations = [
            "Prioritized lower-cost items",
            "Removed \(items.count - optimizedItems.count) items to stay within budget",
            "Consider generic alternatives for remaining items"
        ]
        
        return BudgetOptimizationResult(
            optimizedItems: optimizedItems,
            totalCost: currentCost,
            savings: savings,
            recommendations: recommendations
        )
    }
    
    func suggestBudgetFriendlyAlternatives(for item: GroceryItem) -> [GroceryItem] {
        return sampleGroceryItems.filter { 
            $0.category == item.category && 
            $0.id != item.id && 
            $0.price < item.price 
        }.prefix(3).map { $0 }
    }
    
    func categorizeItem(_ item: GroceryItem) -> String {
        return item.category
    }
    
    func addItemToBudget(_ item: GroceryItem, category: String) {
        if !budgetItems.contains(where: { $0.id == item.id }) {
            budgetItems.append(item)
            spentAmount += item.price
        }
    }
    
    func findBestDeal(for item: GroceryItem) -> GroceryItem? {
        return sampleGroceryItems.first { 
            $0.name.lowercased() == item.name.lowercased() && 
            $0.hasDeal && 
            $0.price < item.price 
        }
    }
} 