//
//  AppState.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/2/25 and 7/3/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Supporting Data Structures for Store Products
struct StorePriceComparison: Identifiable {
    let id = UUID()
    let store: Store
    let storeProduct: StoreProduct
    let distance: Double
    
    var savings: Double? {
        // Calculate savings compared to base price
        let baseItem = sampleGroceryItems.first { $0.id == storeProduct.productId }
        guard let basePrice = baseItem?.price else { return nil }
        return max(0, basePrice - storeProduct.price)
    }
}

// MARK: - Manager Classes
class ShoppingHistoryManager {
    static func sampleHistory() -> [ShoppingHistory] {
        let today = Date()
        let calendar = Calendar.current
        
        return [
            ShoppingHistory(
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                items: sampleGroceryItems.prefix(5).map { $0 },
                totalSpent: 45.67,
                store: "FreshMart",
                category: "Groceries"
            ),
            ShoppingHistory(
                date: calendar.date(byAdding: .day, value: -3, to: today) ?? today,
                items: sampleGroceryItems.prefix(8).map { $0 },
                totalSpent: 78.92,
                store: "FreshMart",
                category: "Groceries"
            ),
            ShoppingHistory(
                date: calendar.date(byAdding: .day, value: -7, to: today) ?? today,
                items: sampleGroceryItems.prefix(12).map { $0 },
                totalSpent: 120.45,
                store: "FreshMart",
                category: "Groceries"
            )
        ]
    }
}

class DietaryGoalManager {
    static func sampleGoals() -> [DietaryGoal] {
        return [
            DietaryGoal(
                type: .calories,
                target: 2000,
                current: 1850,
                unit: "kcal",
                isActive: true
            ),
            DietaryGoal(
                type: .protein,
                target: 150,
                current: 95,
                unit: "g",
                isActive: true
            ),
            DietaryGoal(
                type: .fiber,
                target: 25,
                current: 18,
                unit: "g",
                isActive: true
            )
        ]
    }
}

// MARK: - Main AppState Class
class AppState: ObservableObject {
    
    // MARK: - Core Store Properties
    @Published var selectedStore: Store?
    @Published var nearbyStores: [Store] = []
    @Published var currentStoreProducts: [StoreProduct] = []
    @Published var isLoadingProducts = false
    @Published var searchResults: [StoreProduct] = []
    @Published var lowStockAlerts: [StoreProduct] = []
    
    // MARK: - Shopping & Lists
    @Published var groceryList = GroceryList()
    @Published var shoppingHistory: [ShoppingHistory] = []
    @Published var currentCart: [GroceryItem] = []
    
    // MARK: - User Preferences & Goals
    @Published var dietaryGoals: [DietaryGoal] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var favoriteProducts: [Product] = []
    @Published var mealPlanTemplates: [MealPlanTemplate] = []
    
    // MARK: - Navigation & UI State
    @Published var showingStoreMap = false
    @Published var selectedDeal: Deal?
    @Published var isLocationPermissionGranted = false
    @Published var cartItemCount = 0
    
    // MARK: - Database Service
    private let storeProductService = StoreProductService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupSampleData()
        setupBindings()
    }
    
    // MARK: - Store Product Methods
    
    /// Load products for the currently selected store
    func loadStoreProducts() async {
        guard let selectedStore = selectedStore else { return }
        
        await MainActor.run {
            isLoadingProducts = true
        }
        
        do {
            let products = try await storeProductService.getStoreProducts(for: selectedStore.id)
            await MainActor.run {
                self.currentStoreProducts = products
                self.isLoadingProducts = false
            }
        } catch {
            print("Failed to load store products: \(error)")
            await MainActor.run {
                self.isLoadingProducts = false
            }
        }
    }
    
    /// Search products across all stores or current store
    func searchProducts(_ query: String, currentStoreOnly: Bool = false) async {
        do {
            let results: [StoreProduct]
            if currentStoreOnly, let storeId = selectedStore?.id {
                results = try await storeProductService.searchProducts(query, storeId: storeId)
            } else {
                // For now, search the first available store if no specific store is selected
                let defaultStoreId = selectedStore?.id ?? nearbyStores.first?.id ?? UUID()
                results = try await storeProductService.searchProducts(query, storeId: defaultStoreId)
            }
            await MainActor.run {
                self.searchResults = results
            }
        } catch {
            print("Failed to search products: \(error)")
        }
    }
    
    /// Get store-specific price for a product
    func getStorePrice(for productId: UUID, at storeId: UUID) -> Double? {
        return currentStoreProducts.first { 
            $0.productId == productId && $0.storeId == storeId 
        }?.price
    }
    
    /// Check if product is available at current store
    func isProductAvailable(_ productId: UUID) -> Bool {
        guard let selectedStore = selectedStore else { return false }
        return currentStoreProducts.contains { 
            $0.productId == productId && $0.storeId == selectedStore.id && $0.isAvailable 
        }
    }
    
    /// Get stock level for product at current store
    func getStockLevel(for productId: UUID) -> Int {
        guard let selectedStore = selectedStore else { return 0 }
        return currentStoreProducts.first { 
            $0.productId == productId && $0.storeId == selectedStore.id 
        }?.stockQuantity ?? 0
    }
    
    /// Check for low stock alerts
    func checkLowStockAlerts() async {
        do {
            let lowStockProducts = try await storeProductService.getLowStockProducts()
            await MainActor.run {
                self.lowStockAlerts = lowStockProducts
            }
        } catch {
            print("Failed to check low stock: \(error)")
        }
    }
    
    /// Convert GroceryItem to StoreProduct for current store
    func getStoreProduct(for groceryItem: GroceryItem) -> StoreProduct? {
        guard let selectedStore = selectedStore else { return nil }
        return currentStoreProducts.first { 
            $0.productId == groceryItem.id && $0.storeId == selectedStore.id 
        }
    }
    
    /// Get all available deals at current store
    func getCurrentStoreDeals() -> [StoreProduct] {
        return currentStoreProducts.filter { $0.dealType != nil }
    }
    
    /// Compare prices across stores for a product
    func comparePricesAcrossStores(for productId: UUID) async -> [StorePriceComparison] {
        var comparisons: [StorePriceComparison] = []
        
        for store in sampleLAStores {
            do {
                let storeProducts = try await storeProductService.getStoreProducts(for: store.id)
                if let storeProduct = storeProducts.first(where: { $0.productId == productId }) {
                    let comparison = StorePriceComparison(
                        store: store,
                        storeProduct: storeProduct,
                        distance: calculateDistance(to: store)
                    )
                    comparisons.append(comparison)
                }
            } catch {
                print("Failed to get products for store \(store.name): \(error)")
            }
        }
        
        return comparisons.sorted { $0.storeProduct.price < $1.storeProduct.price }
    }
    
    private func calculateDistance(to store: Store) -> Double {
        // Mock distance calculation - in reality would use user's location
        return Double.random(in: 0.5...10.0)
    }
    
    // MARK: - Store Selection
    func selectStore(_ store: Store) {
        selectedStore = store
        // Load products for the selected store
        Task {
            await loadStoreProducts()
        }
    }
    
    // MARK: - Cart Management
    func addToCart(_ item: GroceryItem) {
        currentCart.append(item)
        cartItemCount = currentCart.count
    }
    
    func removeFromCart(_ item: GroceryItem) {
        currentCart.removeAll { $0.id == item.id }
        cartItemCount = currentCart.count
    }
    
    func clearCart() {
        currentCart.removeAll()
        cartItemCount = 0
    }
    
    // MARK: - Private Helper Methods
    private func setupSampleData() {
        nearbyStores = sampleLAStores
        shoppingHistory = ShoppingHistoryManager.sampleHistory()
        dietaryGoals = DietaryGoalManager.sampleGoals()
    }
    
    private func setupBindings() {
        // Monitor grocery list changes
        groceryList.$groceryItems
            .sink { [weak self] items in
                self?.cartItemCount = items.count
                self?.analyzeShoppingHistory()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Shopping History Analysis
    private func analyzeShoppingHistory() {
        // Enhanced analysis using store-specific data
        guard !groceryList.groceryItems.isEmpty else { return }
        
        // Track which stores user shops at most
        let storeFrequency = groceryList.groceryItems.reduce(into: [UUID: Int]()) { result, item in
            result[item.store.id, default: 0] += 1
        }
        
        // Find preferred store
        if let preferredStoreId = storeFrequency.max(by: { $0.value < $1.value })?.key,
           let preferredStore = sampleLAStores.first(where: { $0.id == preferredStoreId }) {
            // User prefers this store - could suggest deals or new products here
            print("User prefers shopping at: \(preferredStore.name)")
        }
        
        // Analyze spending patterns by store type
        let spendingByStoreType = groceryList.groceryItems.reduce(into: [StoreType: Double]()) { result, item in
            result[item.store.storeType, default: 0] += item.totalPrice
        }
        
        print("Spending by store type: \(spendingByStoreType)")
    }
    
    func getSmartSuggestions() -> [String] {
        // Return some sample smart suggestions based on user shopping history
        return [
            "Add bananas to your cart - you usually buy these weekly",
            "Greek yogurt is on sale at your preferred store",
            "Don't forget milk - you're running low based on your usual pattern",
            "Try organic apples - they're 20% off this week"
        ]
    }
}

// MARK: - Supporting Data Models

struct ShoppingHistory: Identifiable {
    let id = UUID()
    let date: Date
    let items: [GroceryItem]
    let totalSpent: Double
    let store: String
    let category: String
}

struct DietaryGoal: Identifiable {
    let id = UUID()
    let type: GoalType
    let target: Double
    let current: Double
    let unit: String
    let isActive: Bool
    
    enum GoalType: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbohydrates"
        case fat = "Fat"
        case fiber = "Fiber"
        case sugar = "Sugar"
        case sodium = "Sodium"
    }
    
    var progress: Double {
        return current / target
    }
    
    var isOnTrack: Bool {
        return progress >= 0.8 && progress <= 1.2
    }
}

struct UserPreferences: Codable {
    var dietaryRestrictions: [String] = []
    var preferredBrands: [String] = []
    var budgetLimit: Double = 100.0
    var reminderNotifications: Bool = true
    var locationSharing: Bool = false
}

struct MealPlanTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let meals: [String]
    let servings: Int
    let estimatedCost: Double
    let tags: [String]
    let createdAt: Date
}