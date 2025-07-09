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

struct MealPlanTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var tags: [String]
    var meals: [MealPlan.Meal]
    var notes: String?
    var createdAt: Date
    var thumbnail: String // Base64 encoded image or icon name
    
    init(name: String, description: String, tags: [String], meals: [MealPlan.Meal], notes: String? = nil) {
        self.name = name
        self.description = description
        self.tags = tags
        self.meals = meals
        self.notes = notes
        self.createdAt = Date()
        self.thumbnail = "fork.knife" // Default icon
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
    @Published var favoriteRecipes: [Recipe] = []
    @Published var favoriteProducts: [Product] = []
    @Published var mealPlanTemplates: [MealPlanTemplate] = []
    
    // MARK: - New Manager Properties
    // @Published var inventoryManager: InventoryManager
    // @Published var pantryManager: PantryManager
    // @Published var sharedListManager: SharedListManager
    // @Published var suggestionEngine: SuggestionEngine
    // @Published var budgetManager: BudgetManager
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.groceryList = GroceryList()
        self.userPreferences = UserPreferences()
        
        // Initialize managers
        // self.inventoryManager = InventoryManager()
        // self.pantryManager = PantryManager()
        // self.sharedListManager = SharedListManager()
        // self.budgetManager = BudgetManager()
        
        // Initialize suggestion engine with dependencies
        // self.suggestionEngine = SuggestionEngine(
        //     inventoryManager: inventoryManager,
        //     pantryManager: pantryManager
        // )
        
        // Load sample data
        loadSampleData()
        
        // Observe grocery list changes
        groceryList.$groceryItems
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.analyzeShoppingHistory()
                self?.checkPantryForItems()
            }
            .store(in: &cancellables)
        
        // Setup cross-manager communication
        setupManagerCommunication()
    }
    
    // MARK: - Manager Communication Setup
    private func setupManagerCommunication() {
        // Inventory updates trigger suggestions refresh
        // inventoryManager.$inventory
        //     .sink { [weak self] _ in
        //         self?.suggestionEngine.refreshSuggestions()
        //     }
        //     .store(in: &cancellables)
        
        // Pantry updates trigger suggestions refresh
        // pantryManager.$pantryItems
        //     .sink { [weak self] _ in
        //         self?.suggestionEngine.refreshSuggestions()
        //     }
        //     .store(in: &cancellables)
        
        // Shared list updates trigger notifications
        // sharedListManager.$sharedLists
        //     .sink { [weak self] lists in
        //         self?.processSharedListNotifications(lists)
        //     }
        //     .store(in: &cancellables)
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
    
    // MARK: - Pantry Integration
    private func checkPantryForItems() {
        // let pantryCheck = pantryManager.checkPantry(for: groceryList.groceryItems)
        
        // if pantryCheck.hasItemsToRemove {
        //     // Notify user about items already in pantry
        //     let notification = SmartNotification(
        //         type: .shoppingReminder,
        //         title: "Items Already in Pantry",
        //         message: "\(pantryCheck.itemsToRemove.count) items on your list are already in your pantry",
        //         date: Date(),
        //         isRead: false,
        //         action: .addToList
        //     )
        //     notifications.append(notification)
        // }
        
        // if pantryCheck.hasMissingEssentials {
        //     // Suggest missing essentials
        //     let notification = SmartNotification(
        //         type: .shoppingReminder,
        //         title: "Missing Essentials",
        //         message: "Consider adding \(pantryCheck.missingEssentials.count) essential items to your list",
        //         date: Date(),
        //         isRead: false,
        //         action: .addToList
        //     )
        //     notifications.append(notification)
        // }
    }
    
    // MARK: - Shared List Notifications
    private func processSharedListNotifications(_ lists: [SharedList]) {
        // let sharedNotifications = sharedListManager.getNotifications()
        // Placeholder: No-op
    }
    
    // MARK: - Inventory Integration
    func checkItemAvailability(_ item: GroceryItem) -> StockStatus {
        // return inventoryManager.checkStock(for: item)
        return StockStatus.inStock // Placeholder
    }
    
    func getItemSubstitutions(_ item: GroceryItem) -> [GroceryItem] {
        // return inventoryManager.findSubstitutions(for: item)
        return [] // Placeholder
    }
    
    func getLowStockAlerts() -> [InventoryItem] {
        // return inventoryManager.getLowStockItems()
        return [] // Placeholder
    }
    
    func getOutOfStockAlerts() -> [InventoryItem] {
        // return inventoryManager.getOutOfStockItems()
        return [] // Placeholder
    }
    
    // MARK: - Smart Suggestions
    func getSmartSuggestions() -> [SmartSuggestion] {
        // return suggestionEngine.getSuggestions()
        return [] // Placeholder
    }
    
    func getSeasonalSuggestions() -> [SmartSuggestion] {
        // return suggestionEngine.getSeasonalSuggestions()
        return [] // Placeholder
    }
    
    func getFrequentSuggestions() -> [SmartSuggestion] {
        // return suggestionEngine.getFrequentSuggestions()
        return [] // Placeholder
    }
    
    func getWeatherBasedSuggestions() -> [SmartSuggestion] {
        // return suggestionEngine.getWeatherBasedSuggestions()
        return [] // Placeholder
    }
    
    func getHolidaySuggestions() -> [SmartSuggestion] {
        // return suggestionEngine.getHolidaySuggestions()
        return [] // Placeholder
    }
    
    func getBudgetSuggestions(maxBudget: Double) -> [SmartSuggestion] {
        // return suggestionEngine.getBudgetSuggestions(maxBudget: maxBudget)
        return [] // Placeholder
    }
    
    // MARK: - Budget Integration
    func estimateShoppingCost() -> CostEstimate {
        // return budgetManager.estimateTotalCost(for: groceryList.groceryItems)
        return CostEstimate(totalCost: 0, savingsAmount: 0, breakdown: [:]) // Placeholder
    }
    
    func estimateMealPlanCost(for recipes: [Recipe]) -> CostEstimate {
        // return budgetManager.estimateMealPlanCost(for: recipes)
        return CostEstimate(totalCost: 0, savingsAmount: 0, breakdown: [:]) // Placeholder
    }
    
    func optimizeBudgetForTarget(targetBudget: Double) -> BudgetOptimizationResult {
        // return budgetManager.optimizeBudgetForTarget(targetBudget: targetBudget, items: groceryList.groceryItems)
        return BudgetOptimizationResult(optimizedItems: [], totalCost: 0, savings: 0, recommendations: []) // Placeholder
    }
    
    func getBudgetFriendlyAlternatives(for item: GroceryItem) -> [GroceryItem] {
        // return budgetManager.suggestBudgetFriendlyAlternatives(for: item)
        return [] // Placeholder
    }
    
    // MARK: - Pantry Management
    func addItemToPantry(_ item: GroceryItem, quantity: Int = 1, expirationDate: Date? = nil) {
        // pantryManager.addItem(item, quantity: quantity, expirationDate: expirationDate)
    }
    
    func removeItemFromPantry(_ item: GroceryItem) {
        // pantryManager.removeItem(item)
    }
    
    func getExpiringItems(within days: Int = 7) -> [PantryItem] {
        // return pantryManager.getExpiringItems(within: days)
        return [] // Placeholder
    }
    
    func getExpiredItems() -> [PantryItem] {
        // return pantryManager.getExpiredItems()
        return [] // Placeholder
    }
    
    // MARK: - Shared List Management
    func createSharedList(name: String) -> SharedList {
        // return sharedListManager.createSharedList(name: name)
        return SharedList(name: name, createdBy: "Current User", createdAt: Date(), items: [], isActive: true, sharedWith: []) // Placeholder
    }
    
    func addItemToSharedList(_ item: GroceryItem, quantity: Int = 1, to list: SharedList, notes: String? = nil) {
        // sharedListManager.addItemToList(item, quantity: quantity, to: list, notes: notes)
    }
    
    func getActiveSharedLists() -> [SharedList] {
        // return sharedListManager.getActiveLists()
        return [] // Placeholder
    }
    
    func getUrgentSharedItems() -> [SharedListItem] {
        // return sharedListManager.getUrgentItems()
        return [] // Placeholder
    }
    
    // MARK: - Favorites Management
    func addRecipeToFavorites(_ recipe: Recipe) {
        if !favoriteRecipes.contains(where: { $0.id == recipe.id }) {
            favoriteRecipes.append(recipe)
        }
    }
    
    func removeRecipeFromFavorites(_ recipe: Recipe) {
        favoriteRecipes.removeAll { $0.id == recipe.id }
    }
    
    func isRecipeFavorite(_ recipe: Recipe) -> Bool {
        favoriteRecipes.contains(where: { $0.id == recipe.id })
    }
    
    func addProductToFavorites(_ product: Product) {
        if !favoriteProducts.contains(where: { $0.id == product.id }) {
            favoriteProducts.append(product)
        }
    }
    
    func removeProductFromFavorites(_ product: Product) {
        favoriteProducts.removeAll { $0.id == product.id }
    }
    
    func isProductFavorite(_ product: Product) -> Bool {
        return favoriteProducts.contains(where: { $0.id == product.id })
    }
    
    // MARK: - Quick Actions
    func quickAddToGroceryList(_ item: GroceryItem, quantity: Int = 1) {
        groceryList.addItem(item, quantity: quantity)
    }
    
    func quickAddToPantry(_ item: GroceryItem, quantity: Int = 1) {
        // addItemToPantry(item, quantity: quantity)
    }
    
    func quickAddToSharedList(_ item: GroceryItem, quantity: Int = 1) {
        if let activeList = getActiveSharedLists().first {
            // addItemToSharedList(item, quantity: quantity, to: activeList)
        }
    }
    
    func quickAddToBudget(_ item: GroceryItem) {
        // let category = budgetManager.categorizeItem(item)
        // budgetManager.addItemToBudget(item, category: category)
    }
    
    // MARK: - Smart Actions
    func smartAddRecipeIngredients(_ recipe: Recipe) {
        let ingredients = recipe.ingredients.compactMap { ingredient in
            sampleGroceryItems.first { $0.name.lowercased() == ingredient.name.lowercased() }
        }
        
        // Check pantry first
        // let pantryCheck = pantryManager.checkPantry(for: ingredients)
        
        // Only add items not in pantry
        // for item in pantryCheck.itemsToKeep {
        //     groceryList.addItem(item, quantity: 1)
        // }
    }
    
    func smartSubstituteItem(_ originalItem: GroceryItem) -> GroceryItem? {
        let substitutions = getItemSubstitutions(originalItem)
        let budgetAlternatives = getBudgetFriendlyAlternatives(for: originalItem)
        
        // Prefer budget-friendly alternatives
        return budgetAlternatives.first ?? substitutions.first
    }
    
    func getShoppingEfficiencyScore() -> Double {
        let totalItems = groceryList.groceryItems.count
        let itemsWithDeals = groceryList.groceryItems.filter { item in
            // budgetManager.findBestDeal(for: item) != nil
            false // Placeholder
        }.count
        
        // let pantryEfficiency = pantryManager.checkPantry(for: groceryList.groceryItems).itemsToRemove.count
        // let budgetEfficiency = budgetManager.estimateTotalCost(for: groceryList.groceryItems).savingsPercentage
        
        let dealScore = Double(itemsWithDeals) / Double(max(totalItems, 1)) * 30
        // let pantryScore = Double(pantryEfficiency) / Double(max(totalItems, 1)) * 20
        // let budgetScore = min(budgetEfficiency, 50)
        
        return dealScore // + pantryScore + budgetScore
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
