//
//  SmartSubstitutionManager.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import Foundation

class SmartSubstitutionManager: ObservableObject {
    
    // MARK: - Substitution Database
    private static let substitutionDatabase: [String: [SubstitutionRule]] = [
        "milk": [
            SubstitutionRule(
                alternatives: ["almond milk", "soy milk", "oat milk", "coconut milk"],
                reason: "Dairy-free alternatives",
                confidence: 0.9
            ),
            SubstitutionRule(
                alternatives: ["half and half", "heavy cream"],
                reason: "Higher fat content for cooking",
                confidence: 0.7
            )
        ],
        "eggs": [
            SubstitutionRule(
                alternatives: ["flax eggs", "chia eggs", "banana", "applesauce"],
                reason: "Vegan alternatives",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["egg whites", "egg substitute"],
                reason: "Lower cholesterol",
                confidence: 0.9
            )
        ],
        "butter": [
            SubstitutionRule(
                alternatives: ["olive oil", "coconut oil", "avocado oil"],
                reason: "Healthier fats",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["margarine", "vegetable oil"],
                reason: "Similar cooking properties",
                confidence: 0.7
            )
        ],
        "flour": [
            SubstitutionRule(
                alternatives: ["almond flour", "coconut flour", "oat flour"],
                reason: "Gluten-free alternatives",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["whole wheat flour", "bread flour"],
                reason: "Different texture and nutrition",
                confidence: 0.6
            )
        ],
        "sugar": [
            SubstitutionRule(
                alternatives: ["honey", "maple syrup", "agave nectar"],
                reason: "Natural sweeteners",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["stevia", "erythritol", "monk fruit"],
                reason: "Zero-calorie alternatives",
                confidence: 0.9
            )
        ],
        "chicken": [
            SubstitutionRule(
                alternatives: ["turkey", "pork", "beef"],
                reason: "Other protein sources",
                confidence: 0.7
            ),
            SubstitutionRule(
                alternatives: ["tofu", "tempeh", "seitan"],
                reason: "Plant-based protein",
                confidence: 0.8
            )
        ],
        "rice": [
            SubstitutionRule(
                alternatives: ["quinoa", "cauliflower rice", "zucchini noodles"],
                reason: "Lower carb alternatives",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["brown rice", "wild rice", "farro"],
                reason: "Whole grain alternatives",
                confidence: 0.7
            )
        ],
        "pasta": [
            SubstitutionRule(
                alternatives: ["zucchini noodles", "spaghetti squash", "shirataki noodles"],
                reason: "Low-carb alternatives",
                confidence: 0.8
            ),
            SubstitutionRule(
                alternatives: ["whole wheat pasta", "brown rice pasta", "quinoa pasta"],
                reason: "Whole grain alternatives",
                confidence: 0.7
            )
        ]
    ]
    
    // MARK: - Public Methods
    static func findSubstitutions(for item: GroceryItem) -> [SmartSubstitution] {
        let itemName = item.name.lowercased()
        var substitutions: [SmartSubstitution] = []
        
        // Check exact matches first
        if let rules = substitutionDatabase[itemName] {
            for rule in rules {
                let alternatives = findGroceryItems(matching: rule.alternatives)
                if !alternatives.isEmpty {
                    substitutions.append(SmartSubstitution(
                        originalItem: item,
                        alternatives: alternatives,
                        reason: rule.reason,
                        confidence: rule.confidence
                    ))
                }
            }
        }
        
        // Check partial matches
        for (key, rules) in substitutionDatabase {
            if itemName.contains(key) || key.contains(itemName) {
                for rule in rules {
                    let alternatives = findGroceryItems(matching: rule.alternatives)
                    if !alternatives.isEmpty {
                        substitutions.append(SmartSubstitution(
                            originalItem: item,
                            alternatives: alternatives,
                            reason: rule.reason,
                            confidence: rule.confidence * 0.8 // Lower confidence for partial matches
                        ))
                    }
                }
            }
        }
        
        // Sort by confidence
        return substitutions.sorted { $0.confidence > $1.confidence }
    }
    
    static func suggestSubstitutionsForList(_ items: [GroceryItem]) -> [SmartSubstitution] {
        var allSubstitutions: [SmartSubstitution] = []
        
        for item in items {
            let substitutions = findSubstitutions(for: item)
            allSubstitutions.append(contentsOf: substitutions)
        }
        
        // Remove duplicates and sort by confidence
        let uniqueSubstitutions = Dictionary(grouping: allSubstitutions) { $0.originalItem.name }
            .values
            .compactMap { $0.max(by: { $0.confidence < $1.confidence }) }
        
        return uniqueSubstitutions.sorted { $0.confidence > $1.confidence }
    }
    
    static func getOutOfStockSubstitutions() -> [SmartSubstitution] {
        // Simulate out-of-stock items
        let outOfStockItems = [
            GroceryItem(name: "Organic Milk", description: "2% organic milk", price: 4.99, category: "Dairy", aisle: 3, brand: "Horizon"),
            GroceryItem(name: "Large Eggs", description: "Farm fresh large eggs", price: 5.99, category: "Dairy", aisle: 3, brand: "Vital Farms"),
            GroceryItem(name: "Whole Wheat Bread", description: "Fresh whole wheat bread", price: 3.99, category: "Bakery", aisle: 2, brand: "Dave's Killer Bread")
        ]
        
        return outOfStockItems.flatMap { findSubstitutions(for: $0) }
    }
    
    // MARK: - Helper Methods
    private static func findGroceryItems(matching keywords: [String]) -> [GroceryItem] {
        return sampleGroceryItems.filter { item in
            let itemName = item.name.lowercased()
            return keywords.contains { keyword in
                itemName.contains(keyword.lowercased())
            }
        }
    }
}

// MARK: - Substitution Rule
struct SubstitutionRule {
    let alternatives: [String]
    let reason: String
    let confidence: Double
}

// MARK: - Substitution View Models
class SubstitutionViewModel: ObservableObject {
    @Published var substitutions: [SmartSubstitution] = []
    @Published var isLoading = false
    
    func loadSubstitutions(for items: [GroceryItem]) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.substitutions = SmartSubstitutionManager.suggestSubstitutionsForList(items)
            self.isLoading = false
        }
    }
    
    func loadOutOfStockSubstitutions() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.substitutions = SmartSubstitutionManager.getOutOfStockSubstitutions()
            self.isLoading = false
        }
    }
    
    func applySubstitution(_ substitution: SmartSubstitution, to list: GroceryList) {
        // Remove original item
        list.removeItem(substitution.originalItem)
        
        // Add first alternative
        if let alternative = substitution.alternatives.first {
            list.addItem(alternative)
        }
    }
    
    func applySubstitution(_ substitution: SmartSubstitution, with alternative: GroceryItem, to list: GroceryList) {
        // Remove original item
        list.removeItem(substitution.originalItem)
        
        // Add selected alternative
        list.addItem(alternative)
    }
} 