//
//  GroceryItems.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/3/25.
//

import Foundation
import SwiftUI

// MARK: - Type Definitions
enum StockStatus: String, CaseIterable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    case onOrder = "On Order"
    case discontinued = "Discontinued"
}

struct CostEstimate {
    let totalCost: Double
    let savingsAmount: Double
    let savingsPercentage: Double
    let breakdown: [String: Double]
    
    init(totalCost: Double, savingsAmount: Double = 0, breakdown: [String: Double] = [:]) {
        self.totalCost = totalCost
        self.savingsAmount = savingsAmount
        self.savingsPercentage = totalCost > 0 ? (savingsAmount / totalCost) * 100 : 0
        self.breakdown = breakdown
    }
}

struct InventoryItem: Identifiable, Codable {
    let id = UUID()
    let item: GroceryItem
    let currentStock: Int
    let lowStockThreshold: Int
    let lastUpdated: Date
    let supplier: String?
    
    var isLowStock: Bool {
        return currentStock <= lowStockThreshold
    }
    
    var isOutOfStock: Bool {
        return currentStock == 0
    }
}

struct PantryItem: Identifiable, Codable {
    let id = UUID()
    let item: GroceryItem
    let quantity: Int
    let expirationDate: Date?
    let dateAdded: Date
    let notes: String?
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
}

struct SharedList: Identifiable, Codable {
    let id = UUID()
    let name: String
    let createdBy: String
    let createdAt: Date
    let items: [SharedListItem]
    let isActive: Bool
    let sharedWith: [String]
    
    var totalItems: Int {
        return items.count
    }
    
    var urgentItems: [SharedListItem] {
        return items.filter { $0.isUrgent }
    }
}

struct SharedListItem: Identifiable, Codable {
    let id = UUID()
    let item: GroceryItem
    let quantity: Int
    let addedBy: String
    let addedAt: Date
    let notes: String?
    let isUrgent: Bool
    let priority: Priority
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
    }
}

struct SmartSuggestion: Identifiable, Codable {
    let id = UUID()
    let item: GroceryItem
    let reason: String
    let confidence: Double
    let category: SuggestionCategory
    let priority: Int
    
    enum SuggestionCategory: String, CaseIterable, Codable {
        case seasonal = "Seasonal"
        case frequent = "Frequent"
        case weather = "Weather"
        case holiday = "Holiday"
        case budget = "Budget"
        case dietary = "Dietary"
        case pantry = "Pantry"
    }
}

struct BudgetOptimizationResult {
    let optimizedItems: [GroceryItem]
    let totalCost: Double
    let savings: Double
    let recommendations: [String]
}

// MARK: - GroceryItem
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

// Sample grocery items with deals and brands - EXPANDED CATALOG
let sampleGroceryItems: [GroceryItem] = [
    // PRODUCE (Aisle 1)
    GroceryItem(name: "Organic Bananas", description: "Fresh organic bananas", price: 2.99, category: "Produce", aisle: 1, brand: "Organic Valley", hasDeal: true, dealDescription: "2 for $5"),
    GroceryItem(name: "Avocados", description: "Ripe Hass avocados", price: 3.49, category: "Produce", aisle: 1, brand: "Mission", hasDeal: false),
    GroceryItem(name: "Spinach", description: "Fresh baby spinach", price: 4.99, category: "Produce", aisle: 1, brand: "Earthbound Farm", hasDeal: true, dealDescription: "BOGO"),
    GroceryItem(name: "Organic Apples", description: "Honeycrisp organic apples", price: 5.99, category: "Produce", aisle: 1, brand: "Organic Valley", hasDeal: false),
    GroceryItem(name: "Carrots", description: "Fresh baby carrots", price: 2.49, category: "Produce", aisle: 1, brand: "Grimmway Farms", hasDeal: true, dealDescription: "3 for $6"),
    GroceryItem(name: "Broccoli", description: "Fresh broccoli crowns", price: 3.99, category: "Produce", aisle: 1, brand: "Fresh Express", hasDeal: false),
    GroceryItem(name: "Strawberries", description: "Fresh strawberries", price: 4.99, category: "Produce", aisle: 1, brand: "Driscoll's", hasDeal: true, dealDescription: "2 for $8"),
    GroceryItem(name: "Blueberries", description: "Fresh blueberries", price: 6.99, category: "Produce", aisle: 1, brand: "Driscoll's", hasDeal: false),
    GroceryItem(name: "Tomatoes", description: "Roma tomatoes", price: 3.29, category: "Produce", aisle: 1, brand: "Village Farms", hasDeal: false),
    GroceryItem(name: "Lettuce", description: "Iceberg lettuce", price: 2.99, category: "Produce", aisle: 1, brand: "Fresh Express", hasDeal: true, dealDescription: "2 for $5"),
    GroceryItem(name: "Bell Peppers", description: "Mixed bell peppers", price: 4.49, category: "Produce", aisle: 1, brand: "Sunset", hasDeal: false),
    GroceryItem(name: "Onions", description: "Yellow onions", price: 1.99, category: "Produce", aisle: 1, brand: "Farm Fresh", hasDeal: false),
    GroceryItem(name: "Potatoes", description: "Russet potatoes 5lb bag", price: 3.99, category: "Produce", aisle: 1, brand: "Idaho Spuds", hasDeal: true, dealDescription: "2 bags for $7"),
    GroceryItem(name: "Lemons", description: "Fresh lemons", price: 2.99, category: "Produce", aisle: 1, brand: "Sunkist", hasDeal: false),
    GroceryItem(name: "Limes", description: "Fresh limes", price: 2.49, category: "Produce", aisle: 1, brand: "Sunkist", hasDeal: false),
    
    // BAKERY (Aisle 2)
    GroceryItem(name: "Whole Wheat Bread", description: "Fresh whole wheat bread", price: 3.49, category: "Bakery", aisle: 2, brand: "Dave's Killer Bread", hasDeal: false),
    GroceryItem(name: "Croissants", description: "Buttery croissants", price: 4.99, category: "Bakery", aisle: 2, brand: "La Boulangerie", hasDeal: true, dealDescription: "2 for $8"),
    GroceryItem(name: "Sourdough Bread", description: "Fresh sourdough loaf", price: 4.99, category: "Bakery", aisle: 2, brand: "Boudin", hasDeal: false),
    GroceryItem(name: "Bagels", description: "Everything bagels 6-pack", price: 3.99, category: "Bakery", aisle: 2, brand: "Thomas'", hasDeal: true, dealDescription: "2 for $6"),
    GroceryItem(name: "English Muffins", description: "Whole wheat English muffins", price: 2.99, category: "Bakery", aisle: 2, brand: "Thomas'", hasDeal: false),
    GroceryItem(name: "Dinner Rolls", description: "Fresh dinner rolls 8-pack", price: 3.49, category: "Bakery", aisle: 2, brand: "King's Hawaiian", hasDeal: false),
    GroceryItem(name: "Chocolate Muffins", description: "Double chocolate muffins", price: 5.99, category: "Bakery", aisle: 2, brand: "Otis Spunkmeyer", hasDeal: true, dealDescription: "BOGO"),
    
    // DAIRY (Aisle 3)
    GroceryItem(name: "Organic Milk", description: "2% organic milk", price: 4.99, category: "Dairy", aisle: 3, brand: "Organic Valley", hasDeal: false),
    GroceryItem(name: "Greek Yogurt", description: "Plain Greek yogurt", price: 5.99, category: "Dairy", aisle: 3, brand: "Chobani", hasDeal: true, dealDescription: "3 for $12"),
    GroceryItem(name: "Cheddar Cheese", description: "Sharp cheddar cheese", price: 6.99, category: "Dairy", aisle: 3, brand: "Tillamook", hasDeal: false),
    GroceryItem(name: "Whole Milk", description: "Vitamin D whole milk", price: 3.99, category: "Dairy", aisle: 3, brand: "Horizon", hasDeal: false),
    GroceryItem(name: "Almond Milk", description: "Unsweetened almond milk", price: 4.49, category: "Dairy", aisle: 3, brand: "Silk", hasDeal: true, dealDescription: "2 for $8"),
    GroceryItem(name: "Butter", description: "Unsalted butter", price: 5.49, category: "Dairy", aisle: 3, brand: "Land O'Lakes", hasDeal: false),
    GroceryItem(name: "Cream Cheese", description: "Philadelphia cream cheese", price: 3.99, category: "Dairy", aisle: 3, brand: "Philadelphia", hasDeal: true, dealDescription: "2 for $6"),
    GroceryItem(name: "Sour Cream", description: "Regular sour cream", price: 2.99, category: "Dairy", aisle: 3, brand: "Daisy", hasDeal: false),
    GroceryItem(name: "Cottage Cheese", description: "Low-fat cottage cheese", price: 3.49, category: "Dairy", aisle: 3, brand: "Knudsen", hasDeal: false),
    GroceryItem(name: "Mozzarella Cheese", description: "Fresh mozzarella", price: 4.99, category: "Dairy", aisle: 3, brand: "Galbani", hasDeal: false),
    GroceryItem(name: "Parmesan Cheese", description: "Grated Parmesan", price: 7.99, category: "Dairy", aisle: 3, brand: "Kraft", hasDeal: true, dealDescription: "20% off"),
    GroceryItem(name: "Eggs", description: "Large grade A eggs", price: 3.99, category: "Dairy", aisle: 3, brand: "Eggland's Best", hasDeal: false),
    
    // MEAT & SEAFOOD (Aisle 4)
    GroceryItem(name: "Chicken Breast", description: "Boneless skinless chicken breast", price: 12.99, category: "Meat", aisle: 4, brand: "Perdue", hasDeal: false),
    GroceryItem(name: "Ground Beef", description: "85% lean ground beef", price: 8.99, category: "Meat", aisle: 4, brand: "Organic Prairie", hasDeal: true, dealDescription: "2 lbs for $15"),
    GroceryItem(name: "Salmon Fillet", description: "Fresh Atlantic salmon", price: 16.99, category: "Meat", aisle: 4, brand: "Fresh Catch", hasDeal: false),
    GroceryItem(name: "Ground Turkey", description: "93% lean ground turkey", price: 7.99, category: "Meat", aisle: 4, brand: "Jennie-O", hasDeal: false),
    GroceryItem(name: "Pork Chops", description: "Bone-in pork chops", price: 9.99, category: "Meat", aisle: 4, brand: "Smithfield", hasDeal: true, dealDescription: "Family pack $7.99/lb"),
    GroceryItem(name: "Bacon", description: "Thick cut bacon", price: 6.99, category: "Meat", aisle: 4, brand: "Oscar Mayer", hasDeal: false),
    GroceryItem(name: "Deli Ham", description: "Sliced honey ham", price: 8.99, category: "Meat", aisle: 4, brand: "Boar's Head", hasDeal: false),
    GroceryItem(name: "Shrimp", description: "Large frozen shrimp", price: 12.99, category: "Meat", aisle: 4, brand: "Sea Best", hasDeal: true, dealDescription: "2 for $20"),
    
    // PANTRY & CANNED GOODS (Aisle 5)
    GroceryItem(name: "Pasta", description: "Spaghetti pasta", price: 2.99, category: "Pantry", aisle: 5, brand: "Barilla", hasDeal: false),
    GroceryItem(name: "Olive Oil", description: "Extra virgin olive oil", price: 9.99, category: "Pantry", aisle: 5, brand: "California Olive Ranch", hasDeal: true, dealDescription: "20% off"),
    GroceryItem(name: "Rice", description: "Jasmine white rice 5lb", price: 6.99, category: "Pantry", aisle: 5, brand: "Mahatma", hasDeal: false),
    GroceryItem(name: "Canned Tomatoes", description: "Diced tomatoes", price: 1.99, category: "Pantry", aisle: 5, brand: "Hunt's", hasDeal: true, dealDescription: "4 for $6"),
    GroceryItem(name: "Black Beans", description: "Canned black beans", price: 1.49, category: "Pantry", aisle: 5, brand: "Bush's", hasDeal: false),
    GroceryItem(name: "Chicken Broth", description: "Low sodium chicken broth", price: 2.49, category: "Pantry", aisle: 5, brand: "Swanson", hasDeal: false),
    GroceryItem(name: "Peanut Butter", description: "Creamy peanut butter", price: 4.99, category: "Pantry", aisle: 5, brand: "Jif", hasDeal: true, dealDescription: "2 for $8"),
    GroceryItem(name: "Honey", description: "Pure wildflower honey", price: 6.99, category: "Pantry", aisle: 5, brand: "Nature Nate's", hasDeal: false),
    GroceryItem(name: "Oats", description: "Old fashioned oats", price: 3.99, category: "Pantry", aisle: 5, brand: "Quaker", hasDeal: false),
    GroceryItem(name: "Cereal", description: "Honey Nut Cheerios", price: 4.99, category: "Pantry", aisle: 5, brand: "General Mills", hasDeal: true, dealDescription: "2 for $8"),
    GroceryItem(name: "Flour", description: "All-purpose flour 5lb", price: 3.49, category: "Pantry", aisle: 5, brand: "King Arthur", hasDeal: false),
    GroceryItem(name: "Sugar", description: "Granulated sugar 4lb", price: 3.99, category: "Pantry", aisle: 5, brand: "Domino", hasDeal: false),
    
    // SNACKS (Aisle 6)
    GroceryItem(name: "Almonds", description: "Raw almonds", price: 7.99, category: "Snacks", aisle: 6, brand: "Blue Diamond", hasDeal: false),
    GroceryItem(name: "Popcorn", description: "Microwave popcorn", price: 3.99, category: "Snacks", aisle: 6, brand: "Orville Redenbacher", hasDeal: true, dealDescription: "2 for $6"),
    GroceryItem(name: "Potato Chips", description: "Classic potato chips", price: 4.49, category: "Snacks", aisle: 6, brand: "Lay's", hasDeal: false),
    GroceryItem(name: "Granola Bars", description: "Chewy granola bars", price: 5.99, category: "Snacks", aisle: 6, brand: "Nature Valley", hasDeal: true, dealDescription: "2 for $10"),
    GroceryItem(name: "Mixed Nuts", description: "Roasted mixed nuts", price: 8.99, category: "Snacks", aisle: 6, brand: "Planters", hasDeal: false),
    GroceryItem(name: "Crackers", description: "Wheat Thins", price: 3.99, category: "Snacks", aisle: 6, brand: "Nabisco", hasDeal: false),
    GroceryItem(name: "Pretzels", description: "Mini pretzels", price: 2.99, category: "Snacks", aisle: 6, brand: "Snyder's", hasDeal: true, dealDescription: "BOGO"),
    
    // BEVERAGES (Aisle 7)
    GroceryItem(name: "Orange Juice", description: "Fresh squeezed orange juice", price: 5.99, category: "Beverages", aisle: 7, brand: "Tropicana", hasDeal: false),
    GroceryItem(name: "Sparkling Water", description: "Lime sparkling water", price: 4.99, category: "Beverages", aisle: 7, brand: "LaCroix", hasDeal: true, dealDescription: "4 for $15"),
    GroceryItem(name: "Coffee", description: "Ground coffee medium roast", price: 8.99, category: "Beverages", aisle: 7, brand: "Folgers", hasDeal: false),
    GroceryItem(name: "Tea Bags", description: "Green tea bags", price: 4.49, category: "Beverages", aisle: 7, brand: "Lipton", hasDeal: false),
    GroceryItem(name: "Energy Drinks", description: "Energy drink 4-pack", price: 7.99, category: "Beverages", aisle: 7, brand: "Red Bull", hasDeal: true, dealDescription: "2 packs for $14"),
    GroceryItem(name: "Apple Juice", description: "100% apple juice", price: 3.99, category: "Beverages", aisle: 7, brand: "Mott's", hasDeal: false),
    GroceryItem(name: "Soda", description: "Coca-Cola 12-pack", price: 5.99, category: "Beverages", aisle: 7, brand: "Coca-Cola", hasDeal: true, dealDescription: "3 for $15"),
    
    // FROZEN (Aisle 8)
    GroceryItem(name: "Frozen Pizza", description: "Margherita frozen pizza", price: 8.99, category: "Frozen", aisle: 8, brand: "Amy's", hasDeal: false),
    GroceryItem(name: "Ice Cream", description: "Vanilla ice cream", price: 6.99, category: "Frozen", aisle: 8, brand: "Ben & Jerry's", hasDeal: true, dealDescription: "2 for $10"),
    GroceryItem(name: "Frozen Vegetables", description: "Mixed vegetables", price: 2.99, category: "Frozen", aisle: 8, brand: "Birds Eye", hasDeal: false),
    GroceryItem(name: "Frozen Berries", description: "Mixed berry blend", price: 5.99, category: "Frozen", aisle: 8, brand: "Cascade Farm", hasDeal: true, dealDescription: "2 for $10"),
    GroceryItem(name: "Frozen Chicken", description: "Chicken nuggets", price: 7.99, category: "Frozen", aisle: 8, brand: "Tyson", hasDeal: false),
    GroceryItem(name: "Frozen Waffles", description: "Homestyle waffles", price: 3.99, category: "Frozen", aisle: 8, brand: "Eggo", hasDeal: false),
    
    // HOUSEHOLD & PERSONAL CARE (Aisle 9)
    GroceryItem(name: "Paper Towels", description: "Bounty paper towels", price: 12.99, category: "Household", aisle: 9, brand: "Bounty", hasDeal: false),
    GroceryItem(name: "Dish Soap", description: "Dawn dish soap", price: 4.99, category: "Household", aisle: 9, brand: "Dawn", hasDeal: true, dealDescription: "Buy 2 Get 1 Free"),
    GroceryItem(name: "Toilet Paper", description: "Ultra soft toilet paper 12-pack", price: 14.99, category: "Household", aisle: 9, brand: "Charmin", hasDeal: false),
    GroceryItem(name: "Laundry Detergent", description: "Liquid laundry detergent", price: 11.99, category: "Household", aisle: 9, brand: "Tide", hasDeal: true, dealDescription: "$3 off"),
    GroceryItem(name: "Toothpaste", description: "Whitening toothpaste", price: 3.99, category: "Household", aisle: 9, brand: "Crest", hasDeal: false),
    GroceryItem(name: "Shampoo", description: "Daily clarifying shampoo", price: 6.99, category: "Household", aisle: 9, brand: "Head & Shoulders", hasDeal: true, dealDescription: "2 for $12"),
    GroceryItem(name: "Hand Soap", description: "Antibacterial hand soap", price: 2.99, category: "Household", aisle: 9, brand: "Softsoap", hasDeal: false),
    
    // HEALTH & PHARMACY (Aisle 10)
    GroceryItem(name: "Multivitamins", description: "Daily multivitamin", price: 12.99, category: "Health", aisle: 10, brand: "Centrum", hasDeal: false),
    GroceryItem(name: "Pain Relief", description: "Ibuprofen 200mg", price: 8.99, category: "Health", aisle: 10, brand: "Advil", hasDeal: true, dealDescription: "$2 off"),
    GroceryItem(name: "Bandages", description: "Adhesive bandages", price: 4.99, category: "Health", aisle: 10, brand: "Band-Aid", hasDeal: false),
    GroceryItem(name: "Cough Drops", description: "Honey lemon cough drops", price: 3.49, category: "Health", aisle: 10, brand: "Halls", hasDeal: false),
    
    // INTERNATIONAL & SPECIALTY (Aisle 11)
    GroceryItem(name: "Soy Sauce", description: "Low sodium soy sauce", price: 3.99, category: "International", aisle: 11, brand: "Kikkoman", hasDeal: false),
    GroceryItem(name: "Coconut Milk", description: "Unsweetened coconut milk", price: 2.99, category: "International", aisle: 11, brand: "Thai Kitchen", hasDeal: true, dealDescription: "3 for $8"),
    GroceryItem(name: "Quinoa", description: "Organic quinoa", price: 7.99, category: "International", aisle: 11, brand: "Ancient Harvest", hasDeal: false),
    GroceryItem(name: "Hot Sauce", description: "Original hot sauce", price: 2.49, category: "International", aisle: 11, brand: "Tabasco", hasDeal: false),
    GroceryItem(name: "Salsa", description: "Medium chunky salsa", price: 3.99, category: "International", aisle: 11, brand: "Pace", hasDeal: true, dealDescription: "2 for $6"),
]

// Expanded categories for filtering
let groceryCategories = [
    "Produce",
    "Bakery",
    "Dairy", 
    "Meat",
    "Pantry",
    "Snacks",
    "Beverages",
    "Frozen",
    "Household",
    "Health",
    "International"
]
