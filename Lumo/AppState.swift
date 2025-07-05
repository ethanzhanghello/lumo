//
//  AppState.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/2/25 and 7/3/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - New Data Models
struct MealPlan: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var meals: [Meal]
    var notes: String?
    
    struct Meal: Identifiable, Codable {
        let id = UUID()
        var type: MealType
        var recipe: Recipe?
        var customMeal: String?
        var ingredients: [GroceryItem]
        
        enum MealType: String, Codable, CaseIterable {
            case breakfast = "Breakfast"
            case lunch = "Lunch"
            case dinner = "Dinner"
            case snack = "Snack"
        }
    }
}

struct ShoppingHistory: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var items: [GroceryItem]
    var totalSpent: Double
    var store: String
    var category: String
}

struct DietaryGoal: Identifiable, Codable {
    let id = UUID()
    var type: GoalType
    var target: Double
    var current: Double
    var unit: String
    var isActive: Bool
    
    enum GoalType: String, Codable, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fat = "Fat"
        case fiber = "Fiber"
        case sugar = "Sugar"
        case sodium = "Sodium"
    }
}

struct SmartSubstitution: Identifiable, Codable {
    let id = UUID()
    var originalItem: GroceryItem
    var alternatives: [GroceryItem]
    var reason: String
    var confidence: Double // 0.0 to 1.0
}

struct StoreInfo: Identifiable, Codable {
    let id = UUID()
    var name: String
    var address: String
    var hours: String
    var phone: String
    var rating: Double
    var reviews: [StoreReview]
    var parkingInfo: String
    var accessibility: [String]
    
    struct StoreReview: Identifiable, Codable {
        let id = UUID()
        var rating: Int
        var comment: String
        var date: Date
        var author: String
    }
}

struct SmartNotification: Identifiable, Codable {
    let id = UUID()
    var type: NotificationType
    var title: String
    var message: String
    var date: Date
    var isRead: Bool
    var action: NotificationAction?
    
    enum NotificationType: String, Codable {
        case priceDrop = "Price Drop"
        case outOfStock = "Out of Stock"
        case dietaryGoal = "Dietary Goal"
        case mealReminder = "Meal Reminder"
        case shoppingReminder = "Shopping Reminder"
        case dealAlert = "Deal Alert"
    }
    
    enum NotificationAction: String, Codable {
        case addToList = "Add to List"
        case viewDeal = "View Deal"
        case viewRecipe = "View Recipe"
        case trackPrice = "Track Price"
    }
}

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedStore: Store?
    @Published var groceryList: GroceryList
    
    // MARK: - New Feature Properties
    @Published var mealPlans: [MealPlan] = []
    @Published var shoppingHistory: [ShoppingHistory] = []
    @Published var dietaryGoals: [DietaryGoal] = []
    @Published var smartSubstitutions: [SmartSubstitution] = []
    @Published var storeInfo: [StoreInfo] = []
    @Published var notifications: [SmartNotification] = []
    @Published var userPreferences: UserPreferences
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.groceryList = GroceryList()
        self.userPreferences = UserPreferences()
        
        // Load sample data
        loadSampleData()
        
        // Observe grocery list changes
        groceryList.$groceryItems
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.analyzeShoppingHistory()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sample Data Loading
    private func loadSampleData() {
        // Load sample meal plans
        mealPlans = MealPlanManager.sampleMealPlans()
        
        // Load sample shopping history
        shoppingHistory = ShoppingHistoryManager.sampleHistory()
        
        // Load sample dietary goals
        dietaryGoals = DietaryGoalManager.sampleGoals()
        
        // Load sample store info
        storeInfo = StoreInfoManager.sampleStoreInfo()
        
        // Load sample notifications
        notifications = NotificationManager.sampleNotifications()
    }
    
    // MARK: - Shopping History Analysis
    private func analyzeShoppingHistory() {
        // Analyze spending patterns
        let totalSpent = shoppingHistory.reduce(0) { $0 + $1.totalSpent }
        let averageSpent = totalSpent / Double(max(shoppingHistory.count, 1))
        
        // Generate insights
        generateInsights(totalSpent: totalSpent, averageSpent: averageSpent)
    }
    
    private func generateInsights(totalSpent: Double, averageSpent: Double) {
        // Generate smart notifications based on analysis
        let insights = ShoppingInsights.generateInsights(from: shoppingHistory)
        
        // Add relevant notifications
        for insight in insights {
            let notification = SmartNotification(
                type: .shoppingReminder,
                title: insight.title,
                message: insight.message,
                date: Date(),
                isRead: false
            )
            notifications.append(notification)
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var dietaryRestrictions: Set<String> = []
    var budgetLimit: Double = 0
    var preferredStores: [String] = []
    var notificationSettings: NotificationSettings = NotificationSettings()
    var mealPlanningEnabled: Bool = true
    var smartSubstitutionsEnabled: Bool = true
    
    struct NotificationSettings: Codable {
        var priceAlerts: Bool = true
        var mealReminders: Bool = true
        var dietaryGoalAlerts: Bool = true
        var dealAlerts: Bool = true
        var shoppingReminders: Bool = true
    }
}
