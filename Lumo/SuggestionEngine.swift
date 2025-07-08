//
//  SuggestionEngine.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import Combine

class SuggestionEngine: ObservableObject {
    @Published var suggestions: [SmartSuggestion] = []
    
    private let inventoryManager: InventoryManager
    private let pantryManager: PantryManager
    
    init(inventoryManager: InventoryManager, pantryManager: PantryManager) {
        self.inventoryManager = inventoryManager
        self.pantryManager = pantryManager
        refreshSuggestions()
    }
    
    func refreshSuggestions() {
        suggestions = generateSuggestions()
    }
    
    private func generateSuggestions() -> [SmartSuggestion] {
        var allSuggestions: [SmartSuggestion] = []
        
        // Seasonal suggestions
        let seasonalItems = sampleGroceryItems.filter { $0.category == "Produce" }
        for item in seasonalItems.prefix(3) {
            allSuggestions.append(SmartSuggestion(
                item: item,
                reason: "In season now",
                confidence: 0.9,
                category: .seasonal,
                priority: 1
            ))
        }
        
        // Frequent suggestions
        let frequentItems = sampleGroceryItems.filter { $0.category == "Dairy" || $0.category == "Pantry" }
        for item in frequentItems.prefix(3) {
            allSuggestions.append(SmartSuggestion(
                item: item,
                reason: "Frequently purchased",
                confidence: 0.8,
                category: .frequent,
                priority: 2
            ))
        }
        
        // Weather-based suggestions
        let weatherItems = sampleGroceryItems.filter { $0.category == "Beverages" }
        for item in weatherItems.prefix(2) {
            allSuggestions.append(SmartSuggestion(
                item: item,
                reason: "Perfect for hot weather",
                confidence: 0.7,
                category: .weather,
                priority: 3
            ))
        }
        
        // Holiday suggestions
        let holidayItems = sampleGroceryItems.filter { $0.category == "Snacks" }
        for item in holidayItems.prefix(2) {
            allSuggestions.append(SmartSuggestion(
                item: item,
                reason: "Great for gatherings",
                confidence: 0.6,
                category: .holiday,
                priority: 4
            ))
        }
        
        return allSuggestions
    }
    
    func getSuggestions() -> [SmartSuggestion] {
        return suggestions
    }
    
    func getSeasonalSuggestions() -> [SmartSuggestion] {
        return suggestions.filter { $0.category == .seasonal }
    }
    
    func getFrequentSuggestions() -> [SmartSuggestion] {
        return suggestions.filter { $0.category == .frequent }
    }
    
    func getWeatherBasedSuggestions() -> [SmartSuggestion] {
        return suggestions.filter { $0.category == .weather }
    }
    
    func getHolidaySuggestions() -> [SmartSuggestion] {
        return suggestions.filter { $0.category == .holiday }
    }
    
    func getBudgetSuggestions(maxBudget: Double) -> [SmartSuggestion] {
        return suggestions.filter { $0.item.price <= maxBudget * 0.1 } // Items under 10% of budget
    }
} 