//
//  GroceryItems.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/3/25.
//

import Foundation
import SwiftUI

struct GroceryItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let category: String
    let aisle: Int
    let brand: String
    let hasDeal: Bool
    let dealDescription: String?
    
    init(name: String, description: String, price: Double, category: String, aisle: Int, brand: String = "", hasDeal: Bool = false, dealDescription: String? = nil) {
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.aisle = aisle
        self.brand = brand
        self.hasDeal = hasDeal
        self.dealDescription = dealDescription
    }
}

// Sample grocery items with deals and brands
let sampleGroceryItems: [GroceryItem] = [
    // Produce
    GroceryItem(name: "Organic Bananas", description: "Fresh organic bananas", price: 2.99, category: "Produce", aisle: 1, brand: "Organic Valley", hasDeal: true, dealDescription: "2 for $5"),
    GroceryItem(name: "Avocados", description: "Ripe Hass avocados", price: 3.49, category: "Produce", aisle: 1, brand: "Mission", hasDeal: false),
    GroceryItem(name: "Spinach", description: "Fresh baby spinach", price: 4.99, category: "Produce", aisle: 1, brand: "Earthbound Farm", hasDeal: true, dealDescription: "BOGO"),
    
    // Dairy
    GroceryItem(name: "Organic Milk", description: "2% organic milk", price: 4.99, category: "Dairy", aisle: 3, brand: "Organic Valley", hasDeal: false),
    GroceryItem(name: "Greek Yogurt", description: "Plain Greek yogurt", price: 5.99, category: "Dairy", aisle: 3, brand: "Chobani", hasDeal: true, dealDescription: "3 for $12"),
    GroceryItem(name: "Cheddar Cheese", description: "Sharp cheddar cheese", price: 6.99, category: "Dairy", aisle: 3, brand: "Tillamook", hasDeal: false),
    
    // Bakery
    GroceryItem(name: "Whole Wheat Bread", description: "Fresh whole wheat bread", price: 3.49, category: "Bakery", aisle: 2, brand: "Dave's Killer Bread", hasDeal: false),
    GroceryItem(name: "Croissants", description: "Buttery croissants", price: 4.99, category: "Bakery", aisle: 2, brand: "La Boulangerie", hasDeal: true, dealDescription: "2 for $8"),
    
    // Meat
    GroceryItem(name: "Chicken Breast", description: "Boneless skinless chicken breast", price: 12.99, category: "Meat", aisle: 4, brand: "Perdue", hasDeal: false),
    GroceryItem(name: "Ground Beef", description: "85% lean ground beef", price: 8.99, category: "Meat", aisle: 4, brand: "Organic Prairie", hasDeal: true, dealDescription: "2 lbs for $15"),
    
    // Pantry
    GroceryItem(name: "Pasta", description: "Spaghetti pasta", price: 2.99, category: "Pantry", aisle: 5, brand: "Barilla", hasDeal: false),
    GroceryItem(name: "Olive Oil", description: "Extra virgin olive oil", price: 9.99, category: "Pantry", aisle: 5, brand: "California Olive Ranch", hasDeal: true, dealDescription: "20% off"),
    
    // Snacks
    GroceryItem(name: "Almonds", description: "Raw almonds", price: 7.99, category: "Snacks", aisle: 6, brand: "Blue Diamond", hasDeal: false),
    GroceryItem(name: "Popcorn", description: "Microwave popcorn", price: 3.99, category: "Snacks", aisle: 6, brand: "Orville Redenbacher", hasDeal: true, dealDescription: "2 for $6"),
    
    // Beverages
    GroceryItem(name: "Orange Juice", description: "Fresh squeezed orange juice", price: 5.99, category: "Beverages", aisle: 7, brand: "Tropicana", hasDeal: false),
    GroceryItem(name: "Sparkling Water", description: "Lime sparkling water", price: 4.99, category: "Beverages", aisle: 7, brand: "LaCroix", hasDeal: true, dealDescription: "4 for $15"),
    
    // Frozen
    GroceryItem(name: "Frozen Pizza", description: "Margherita frozen pizza", price: 8.99, category: "Frozen", aisle: 8, brand: "Amy's", hasDeal: false),
    GroceryItem(name: "Ice Cream", description: "Vanilla ice cream", price: 6.99, category: "Frozen", aisle: 8, brand: "Ben & Jerry's", hasDeal: true, dealDescription: "2 for $10"),
    
    // Household
    GroceryItem(name: "Paper Towels", description: "Bounty paper towels", price: 12.99, category: "Household", aisle: 9, brand: "Bounty", hasDeal: false),
    GroceryItem(name: "Dish Soap", description: "Dawn dish soap", price: 4.99, category: "Household", aisle: 9, brand: "Dawn", hasDeal: true, dealDescription: "Buy 2 Get 1 Free")
]

// Categories for filtering
let groceryCategories = [
    "Produce",
    "Dairy", 
    "Bakery",
    "Meat",
    "Pantry",
    "Snacks",
    "Beverages",
    "Frozen",
    "Household"
]
