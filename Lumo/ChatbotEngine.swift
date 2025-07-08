//
//  ChatbotEngine.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation
import SwiftUI

@MainActor
class ChatbotEngine: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    
    private let openAIService = OpenAIService()
    private let intentRecognizer = IntentRecognizer()
    let appState: AppState // Make this accessible
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Message Handling
    func sendMessage(_ content: String) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        isTyping = true
        let response = await processMessage(content)
        isTyping = false
        messages.append(response)
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    // MARK: - Message Processing
    private func processMessage(_ content: String) async -> ChatMessage {
        let intentResult = intentRecognizer.recognizeIntent(from: content)
        let primaryIntent = intentResult.primaryIntent
        let confidence = intentResult.confidence
        
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Show Aisle", action: .showAisle, icon: "location"),
            ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        switch primaryIntent {
        case .recipe:
            return await handleRecipeRequest(content)
        case .productSearch:
            return await handleProductSearch(content)
        case .dealSearch:
            return await handleDealSearch(content)
        case .listManagement:
            return await handleListManagement(content)
        case .mealPlanning:
            return await handleMealPlanning(content)
        case .storeInfo:
            return await handleStoreInfo(content)
        case .dietaryFilter:
            return await handleDietaryFilter(content)
        case .inventoryCheck:
            return await handleInventoryCheck(content)
        case .pantryManagement:
            return await handlePantryManagement(content)
        case .sharedList:
            return await handleSharedList(content)
        case .budgetOptimization:
            return await handleBudgetOptimization(content)
        case .smartSuggestions:
            return await handleSmartSuggestions(content)
        case .general:
            return await handleGeneralQuery(content)
        }
    }
    
    // MARK: - Enhanced Intent Handlers
    private func handleRecipeRequest(_ query: String) async -> ChatMessage {
        let recipes = RecipeDatabase.searchRecipes(query: query)
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Show Aisle", action: .showAisle, icon: "location"),
            ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        if let recipe = recipes.first {
            // Check inventory for ingredients
            let ingredients = recipe.ingredients.compactMap { ingredient in
                sampleGroceryItems.first { $0.name.lowercased() == ingredient.name.lowercased() }
            }
            
            var inventoryStatus = ""
            for ingredient in ingredients {
                let status = appState.checkItemAvailability(ingredient)
                if status == .outOfStock {
                    inventoryStatus += "⚠️ \(ingredient.name) is out of stock\n"
                } else if status == .lowStock {
                    inventoryStatus += "📉 \(ingredient.name) is low in stock\n"
                }
            }
            
            let costEstimate = appState.estimateMealPlanCost(for: [recipe])
            
            let response = """
            Here's a great recipe for you! 🍳
            
            **\(recipe.name)**
            \(recipe.description)
            
            ⏱️ **Time**: \(recipe.prepTime + recipe.cookTime) minutes
            👥 **Servings**: \(recipe.servings)
            💰 **Estimated Cost**: $\(String(format: "%.2f", costEstimate.totalCost))
            💸 **Savings**: $\(String(format: "%.2f", costEstimate.savingsAmount)) (\(String(format: "%.1f", costEstimate.savingsPercentage))%)
            ⭐ **Rating**: \(recipe.rating)/5 (\(recipe.reviewCount) reviews)
            
            **Ingredients** (Aisle locations included):
            \(recipe.ingredients.map { "• \($0.displayAmount) \($0.name) (Aisle \($0.aisle))" }.joined(separator: "\n"))
            
            \(inventoryStatus.isEmpty ? "" : "\n**Inventory Status**:\n\(inventoryStatus)")
            
            Would you like me to add all ingredients to your shopping list and create a route through the store?
            """
            return ChatMessage(
                content: response,
                isUser: false,
                recipe: recipe,
                actionButtons: actionButtons
            )
        } else {
            let aiResponse = await openAIService.getRecipeSuggestion(for: query)
            return ChatMessage(content: aiResponse, isUser: false, actionButtons: actionButtons)
        }
    }
    
    private func handleProductSearch(_ query: String) async -> ChatMessage {
        let products = DealsData.searchProducts(query: query)
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Find Route", action: .showAisle, icon: "location"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Show Deals", action: .showDeals, icon: "tag"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        if let product = products.first {
            // Convert Product to GroceryItem for inventory check
            let groceryItem = GroceryItem(
                name: product.name,
                description: product.description,
                price: product.price,
                category: product.category,
                aisle: product.aisle,
                brand: product.brand,
                hasDeal: product.dealType != nil,
                dealDescription: product.dealType?.rawValue
            )
            
            let stockStatus = appState.checkItemAvailability(groceryItem)
            let substitutions = appState.getItemSubstitutions(groceryItem)
            let budgetAlternatives = appState.getBudgetFriendlyAlternatives(for: groceryItem)
            
            var statusMessage = ""
            switch stockStatus {
            case .inStock:
                statusMessage = "✅ In Stock"
            case .lowStock:
                statusMessage = "📉 Low Stock"
            case .outOfStock:
                statusMessage = "❌ Out of Stock"
            case .onOrder:
                statusMessage = "📦 On Order"
            case .discontinued:
                statusMessage = "🚫 Discontinued"
            }
            
            var alternativesMessage = ""
            if !substitutions.isEmpty {
                alternativesMessage += "\n**Substitutions Available**:\n"
                alternativesMessage += substitutions.prefix(3).map { "• \($0.name) - $\(String(format: "%.2f", $0.price))" }.joined(separator: "\n")
            }
            
            if !budgetAlternatives.isEmpty {
                alternativesMessage += "\n**Budget Alternatives**:\n"
                alternativesMessage += budgetAlternatives.prefix(3).map { "• \($0.name) - $\(String(format: "%.2f", $0.price))" }.joined(separator: "\n")
            }
            
            let response = """
            Found it! 📍
            
            **\(product.name)** by \(product.brand)
            📍 **Location**: Aisle \(product.aisle), \(product.shelfPosition)
            💰 **Price**: $\(String(format: "%.2f", product.price))
            📦 **Stock**: \(statusMessage)
            
            \(product.dealType != nil ? "🎉 **Deal**: \(product.dealType?.rawValue ?? "") - Save $\(String(format: "%.2f", product.price - (product.discountPrice ?? product.price)))" : "")
            
            \(alternativesMessage)
            """
            return ChatMessage(
                content: response,
                isUser: false,
                product: product,
                actionButtons: actionButtons
            )
        } else {
            let aiResponse = await openAIService.getProductGuidance(for: query)
            return ChatMessage(content: aiResponse, isUser: false, actionButtons: actionButtons)
        }
    }
    
    private func handleDealSearch(_ query: String) async -> ChatMessage {
        let deals = DealsData.getActiveDeals()
        let actionButtons = [
            ChatActionButton(title: "Clip Coupon", action: .clipCoupon, icon: "tag"),
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "View Deals", action: .showDeals, icon: "list.bullet")
        ]
        if let deal = deals.first {
            let response = """
            Great deals available! 🎉
            
            **\(deal.title)**
            \(deal.description)
            
            💰 **Discount**: \(deal.discountValue)\(deal.dealType == .percentageOff ? "%" : "$")
            📅 **Valid**: \(formatDate(deal.endDate))
            🏪 **Stores**: \(deal.applicableStores.map { $0.name }.joined(separator: ", "))
            
            **Benefits**:
            \(deal.benefits.map { "• \($0)" }.joined(separator: "\n"))
            """
            return ChatMessage(
                content: response,
                isUser: false,
                deal: deal,
                actionButtons: actionButtons
            )
        } else {
            return ChatMessage(
                content: "I found some great deals! Check out our deals page for the latest offers and digital coupons. 🎉",
                isUser: false,
                actionButtons: actionButtons
            )
        }
    }
    
    private func handleListManagement(_ query: String) async -> ChatMessage {
        let actionButtons = [
            ChatActionButton(title: "View List", action: .addToList, icon: "list.bullet"),
            ChatActionButton(title: "Clear List", action: .addToList, icon: "trash"),
            ChatActionButton(title: "Share List", action: .shareRecipe, icon: "square.and.arrow.up")
        ]
        return ChatMessage(
            content: "I can help you manage your shopping list! You can add items, view your current list, or share it with family members. What would you like to do? 📋",
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleMealPlanning(_ query: String) async -> ChatMessage {
        // Enhanced AI Meal Builder functionality
        let lowercased = query.lowercased()
        
        // Check for specific meal builder requests
        if lowercased.contains("build") || lowercased.contains("dinner") || lowercased.contains("lunch") || 
           lowercased.contains("breakfast") || lowercased.contains("bbq") || lowercased.contains("party") ||
           lowercased.contains("week") || lowercased.contains("plan") || lowercased.contains("surprise") ||
           lowercased.contains("pantry") || lowercased.contains("healthy") || lowercased.contains("vegetarian") ||
           lowercased.contains("vegan") || lowercased.contains("budget") {
            
            let mealBuilderResponse = await openAIService.getMealBuilderResponse(for: query)
            let actionButtons = [
                ChatActionButton(title: "Add All to Cart", action: .addToCart, icon: "cart.badge.plus"),
                ChatActionButton(title: "Add to Meal Plan", action: .mealPlan, icon: "calendar.badge.plus"),
                ChatActionButton(title: "View Ingredients", action: .showIngredients, icon: "list.bullet"),
                ChatActionButton(title: "Find Substitutions", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
                ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice"),
                ChatActionButton(title: "Build from Pantry", action: .pantryCheck, icon: "cabinet")
            ]
            
            return ChatMessage(
                content: mealBuilderResponse,
                isUser: false,
                actionButtons: actionButtons
            )
        }
        
        // General meal planning options
        let actionButtons = [
            ChatActionButton(title: "🍽️ AI Meal Builder", action: .mealPlan, icon: "brain.head.profile"),
            ChatActionButton(title: "Quick Meals", action: .mealPlan, icon: "bolt"),
            ChatActionButton(title: "Budget Meals", action: .budgetFilter, icon: "dollarsign.circle"),
            ChatActionButton(title: "Pantry Check", action: .pantryCheck, icon: "cabinet"),
            ChatActionButton(title: "30-Min Meals", action: .timeFilter, icon: "clock"),
            ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice")
        ]
        
        let response = """
        🍽️ **AI Meal Builder** — Your Smart Shopping Companion!
        
        I can create complete, personalized meal plans that automatically build your shopping list and integrate with your calendar.
        
        **Try asking me:**
        • "Build a dinner for four"
        • "Give me a healthy meal plan for the week"
        • "Plan a summer BBQ"
        • "Surprise me with a vegetarian dinner"
        • "Build meals around what I have in my pantry"
        
        **What I'll do:**
        ✅ Generate 1-7 meals based on your preferences
        ✅ Auto-populate shopping list with exact quantities
        ✅ Show aisle locations for every ingredient
        ✅ Suggest substitutions for dietary restrictions
        ✅ Add meals to your calendar with reminders
        ✅ Integrate with your shopping cart
        
        What type of meal would you like me to build for you? 🎯
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleStoreInfo(_ query: String) async -> ChatMessage {
        let store = sampleLAStores.first
        let actionButtons = [
            ChatActionButton(title: "Store Hours", action: .storeInfo, icon: "clock"),
            ChatActionButton(title: "Store Map", action: .navigateTo, icon: "map"),
            ChatActionButton(title: "Find Section", action: .findInStore, icon: "location")
        ]
        let response = """
        **\(store?.name ?? "Lumo Store")** Information 🏪
        
        📍 **Address**: \(store?.address ?? ""), \(store?.city ?? "") \(store?.state ?? "") \(store?.zip ?? "")
        📞 **Phone**: \(store?.phone ?? "")
        🕒 **Hours**: \(store?.hours ?? "")
        ⭐ **Rating**: \(store?.rating ?? 0)/5
        
        I can help you find specific sections, check store hours, or navigate to different areas of the store!
        """
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleDietaryFilter(_ query: String) async -> ChatMessage {
        let actionButtons = [
            ChatActionButton(title: "Vegetarian", action: .filterByDiet, icon: "leaf"),
            ChatActionButton(title: "Vegan", action: .filterByDiet, icon: "leaf.arrow.circlepath"),
            ChatActionButton(title: "Gluten-Free", action: .filterByDiet, icon: "exclamationmark.shield"),
            ChatActionButton(title: "Nut-Free", action: .allergenCheck, icon: "exclamationmark.triangle")
        ]
        // Get a dynamic response from OpenAI
        let aiResponse = await openAIService.getGeneralResponse(for: query + " (focus on dietary needs, allergens, and restrictions)")
        return ChatMessage(
            content: aiResponse,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleInventoryCheck(_ query: String) async -> ChatMessage {
        let lowStockItems = appState.getLowStockAlerts()
        let outOfStockItems = appState.getOutOfStockAlerts()
        
        let actionButtons = [
            ChatActionButton(title: "View Low Stock", action: .showInventory, icon: "exclamationmark.triangle"),
            ChatActionButton(title: "Find Substitutions", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        var response = "📦 **Inventory Status Report**\n\n"
        
        if !lowStockItems.isEmpty {
            response += "⚠️ **Low Stock Items** (\(lowStockItems.count)):\n"
            response += lowStockItems.prefix(5).map { "• \($0.item.name) - \($0.currentStock) left" }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if !outOfStockItems.isEmpty {
            response += "❌ **Out of Stock Items** (\(outOfStockItems.count)):\n"
            response += outOfStockItems.prefix(5).map { "• \($0.item.name)" }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if lowStockItems.isEmpty && outOfStockItems.isEmpty {
            response += "✅ All items are well-stocked!"
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handlePantryManagement(_ query: String) async -> ChatMessage {
        let expiringItems = appState.getExpiringItems(within: 7)
        let expiredItems = appState.getExpiredItems()
        // let pantryCheck = appState.pantryManager.checkPantry(for: appState.groceryList.groceryItems)
        let pantryCheck = PantryCheckResult(itemsToRemove: [], itemsToKeep: [], missingEssentials: []) // Placeholder
        
        let actionButtons = [
            ChatActionButton(title: "View Pantry", action: .showPantry, icon: "cabinet"),
            ChatActionButton(title: "Scan Barcode", action: .scanBarcode, icon: "barcode"),
            ChatActionButton(title: "Remove Expired", action: .removeExpired, icon: "trash"),
            ChatActionButton(title: "Add to Pantry", action: .addToPantry, icon: "plus.circle")
        ]
        
        var response = "🏠 **Pantry Management**\n\n"
        
        if !expiringItems.isEmpty {
            response += "⏰ **Expiring Soon** (\(expiringItems.count)):\n"
            response += expiringItems.prefix(5).map { item in
                let days = item.daysUntilExpiration ?? 0
                return "• \(item.item.name) - expires in \(days) days"
            }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if !expiredItems.isEmpty {
            response += "🚫 **Expired Items** (\(expiredItems.count)):\n"
            response += expiredItems.prefix(5).map { "• \($0.item.name)" }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if pantryCheck.hasItemsToRemove {
            response += "✅ **Already in Pantry** (\(pantryCheck.itemsToRemove.count)):\n"
            response += "These items on your list are already in your pantry and can be removed.\n\n"
        }
        
        if pantryCheck.hasMissingEssentials {
            response += "📝 **Missing Essentials** (\(pantryCheck.missingEssentials.count)):\n"
            response += "Consider adding these essential items to your list.\n\n"
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleSharedList(_ query: String) async -> ChatMessage {
        let activeLists = appState.getActiveSharedLists()
        let urgentItems = appState.getUrgentSharedItems()
        
        let actionButtons = [
            ChatActionButton(title: "View Lists", action: .showSharedLists, icon: "person.3"),
            ChatActionButton(title: "Add Item", action: .addToSharedList, icon: "plus.circle"),
            ChatActionButton(title: "Urgent Items", action: .showUrgent, icon: "exclamationmark.triangle"),
            ChatActionButton(title: "Share List", action: .shareList, icon: "square.and.arrow.up")
        ]
        
        var response = "👨‍👩‍👧‍👦 **Shared Lists**\n\n"
        
        if !activeLists.isEmpty {
            response += "📋 **Active Lists** (\(activeLists.count)):\n"
            for list in activeLists.prefix(3) {
                let progress = Int((Double(list.items.count) / Double(max(list.totalItems, 1))) * 100)
                response += "• \(list.name) - \(progress)% complete (\(list.items.count)/\(list.totalItems))\n"
            }
            response += "\n"
        }
        
        if !urgentItems.isEmpty {
            response += "⚠️ **Urgent Items** (\(urgentItems.count)):\n"
            response += urgentItems.prefix(5).map { "• \($0.item.name) - added by \($0.addedBy)" }.joined(separator: "\n")
            response += "\n"
        }
        
        response += "👥 **Shared With**:\n"
        for list in activeLists {
            if !list.sharedWith.isEmpty {
                response += "• \(list.name): \(list.sharedWith.joined(separator: ", "))\n"
            }
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleBudgetOptimization(_ query: String) async -> ChatMessage {
        let costEstimate = appState.estimateShoppingCost()
        let efficiencyScore = appState.getShoppingEfficiencyScore()
        
        let actionButtons = [
            ChatActionButton(title: "View Budget", action: .showBudget, icon: "dollarsign.circle"),
            ChatActionButton(title: "Optimize List", action: .optimizeBudget, icon: "chart.line.uptrend.xyaxis"),
            ChatActionButton(title: "Find Deals", action: .showDeals, icon: "tag"),
            ChatActionButton(title: "Budget Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath")
        ]
        
        let response = """
        💰 **Budget Analysis**
        
        **Current Shopping List**:
        💵 Total Cost: $\(String(format: "%.2f", costEstimate.totalCost))
        💸 Savings: $\(String(format: "%.2f", costEstimate.savingsAmount)) (\(String(format: "%.1f", costEstimate.savingsPercentage))%)
        
        **Efficiency Score**: \(Int(efficiencyScore))/100
        
        **Category Breakdown**:
        \(costEstimate.breakdown.map { "• \($0.key): $\(String(format: "%.2f", $0.value))" }.joined(separator: "\n"))
        
        Would you like me to optimize your list for a specific budget?
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleSmartSuggestions(_ query: String) async -> ChatMessage {
        let seasonalSuggestions = appState.getSeasonalSuggestions()
        let frequentSuggestions = appState.getFrequentSuggestions()
        let weatherSuggestions = appState.getWeatherBasedSuggestions()
        let holidaySuggestions = appState.getHolidaySuggestions()
        
        let actionButtons = [
            ChatActionButton(title: "Seasonal Items", action: .showSeasonal, icon: "leaf"),
            ChatActionButton(title: "Frequent Items", action: .showFrequent, icon: "clock.arrow.circlepath"),
            ChatActionButton(title: "Weather Based", action: .showWeather, icon: "cloud.sun"),
            ChatActionButton(title: "Holiday Items", action: .showHoliday, icon: "gift"),
            ChatActionButton(title: "Add All", action: .addAllSuggestions, icon: "plus.circle")
        ]
        
        var response = "🧠 **Smart Suggestions**\n\n"
        
        if !seasonalSuggestions.isEmpty {
            response += "🍂 **Seasonal Items** (\(seasonalSuggestions.count)):\n"
            response += seasonalSuggestions.prefix(3).map { "• \($0.item.name) - \($0.reason)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !frequentSuggestions.isEmpty {
            response += "🔄 **Frequent Purchases** (\(frequentSuggestions.count)):\n"
            response += frequentSuggestions.prefix(3).map { "• \($0.item.name) - \($0.reason)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !weatherSuggestions.isEmpty {
            response += "🌤️ **Weather Based** (\(weatherSuggestions.count)):\n"
            response += weatherSuggestions.prefix(3).map { "• \($0.item.name) - \($0.reason)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !holidaySuggestions.isEmpty {
            response += "🎉 **Holiday Items** (\(holidaySuggestions.count)):\n"
            response += holidaySuggestions.prefix(3).map { "• \($0.item.name) - \($0.reason)" }.joined(separator: "\n")
            response += "\n"
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleGeneralQuery(_ query: String) async -> ChatMessage {
        let aiResponse = await openAIService.getGeneralResponse(for: query)
        return ChatMessage(content: aiResponse, isUser: false)
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Advanced Intent Recognition
class IntentRecognizer {
    enum Intent: CaseIterable {
        case recipe
        case productSearch
        case dealSearch
        case listManagement
        case mealPlanning
        case storeInfo
        case dietaryFilter
        case inventoryCheck
        case pantryManagement
        case sharedList
        case budgetOptimization
        case smartSuggestions
        case general
        
        var displayName: String {
            switch self {
            case .recipe: return "Recipe"
            case .productSearch: return "Product Search"
            case .dealSearch: return "Deal Search"
            case .listManagement: return "List Management"
            case .mealPlanning: return "Meal Planning"
            case .storeInfo: return "Store Information"
            case .dietaryFilter: return "Dietary Filter"
            case .inventoryCheck: return "Inventory Check"
            case .pantryManagement: return "Pantry Management"
            case .sharedList: return "Shared List"
            case .budgetOptimization: return "Budget Optimization"
            case .smartSuggestions: return "Smart Suggestions"
            case .general: return "General"
            }
        }
    }
    
    struct IntentResult: Equatable {
        let primaryIntent: Intent
        let confidence: Double
        let secondaryIntents: [(Intent, Double)]
        let entities: [Entity]
        let context: QueryContext
        
        static func == (lhs: IntentResult, rhs: IntentResult) -> Bool {
            lhs.primaryIntent == rhs.primaryIntent &&
            abs(lhs.confidence - rhs.confidence) < 0.0001 &&
            lhs.secondaryIntents.map { $0.0 } == rhs.secondaryIntents.map { $0.0 } &&
            lhs.entities == rhs.entities
        }
    }
    
    struct Entity: Equatable {
        let type: EntityType
        let value: String
        let confidence: Double
        let position: Range<String.Index>
        
        static func == (lhs: Entity, rhs: Entity) -> Bool {
            lhs.type == rhs.type && lhs.value == rhs.value
        }
    }
    
    enum EntityType {
        case product
        case brand
        case category
        case aisle
        case price
        case quantity
        case dietary
        case meal
        case time
        case location
    }
    
    struct QueryContext {
        let isQuestion: Bool
        let urgency: Urgency
        let complexity: Complexity
        let previousIntents: [Intent]
    }
    
    enum Urgency {
        case low, medium, high
    }
    
    enum Complexity {
        case simple, moderate, complex
    }
    
    // MARK: - Pattern Matchers
    private let recipePatterns: [(pattern: String, weight: Double)] = [
        ("recipe", 10.0),
        ("cook", 8.0),
        ("make", 7.0),
        ("dish", 6.0),
        ("meal", 5.0),
        ("dinner", 4.0),
        ("lunch", 4.0),
        ("breakfast", 4.0),
        ("ingredient", 6.0),
        ("how to", 3.0),
        ("instructions", 3.0),
        ("preparation", 3.0),
        ("cooking", 3.0),
        ("baking", 3.0),
        ("chef", 2.0),
        ("cuisine", 2.0),
        ("food", 4.0),
        ("dish", 5.0),
        ("meal prep", 6.0),
        ("cookbook", 3.0),
        ("kitchen", 2.0),
        ("homemade", 4.0),
        ("from scratch", 5.0),
        ("cooking time", 3.0),
        ("serving size", 3.0),
        ("nutritional info", 2.0)
    ]
    
    private let productSearchPatterns: [(pattern: String, weight: Double)] = [
        ("find", 8.0),
        ("where", 7.0),
        ("location", 6.0),
        ("aisle", 8.0),
        ("shelf", 6.0),
        ("product", 5.0),
        ("item", 5.0),
        ("brand", 4.0),
        ("look for", 3.0),
        ("search", 3.0),
        ("locate", 3.0),
        ("position", 2.0),
        ("section", 2.0),
        ("grocery", 6.0),
        ("food", 4.0),
        ("produce", 7.0),
        ("dairy", 7.0),
        ("meat", 7.0),
        ("bakery", 7.0),
        ("frozen", 7.0),
        ("pantry", 6.0),
        ("beverages", 6.0),
        ("snacks", 6.0),
        ("organic", 5.0),
        ("fresh", 5.0),
        ("canned", 5.0),
        ("frozen food", 6.0),
        ("deli", 6.0),
        ("seafood", 6.0),
        ("condiments", 5.0),
        ("spices", 5.0),
        ("cereal", 5.0),
        ("bread", 5.0),
        ("milk", 5.0),
        ("eggs", 5.0),
        ("cheese", 5.0),
        ("vegetables", 6.0),
        ("fruits", 6.0),
        ("meat department", 7.0),
        ("produce section", 7.0)
    ]
    
    private let dealSearchPatterns: [(pattern: String, weight: Double)] = [
        ("deal", 10.0),
        ("coupon", 9.0),
        ("discount", 8.0),
        ("sale", 7.0),
        ("offer", 6.0),
        ("save", 5.0),
        ("price", 4.0),
        ("cheap", 3.0),
        ("budget", 3.0),
        ("on sale", 8.0),
        ("clearance", 7.0),
        ("promotion", 6.0),
        ("special", 5.0),
        ("reduced", 4.0),
        ("markdown", 4.0),
        ("bogo", 8.0),
        ("buy one get one", 9.0),
        ("2 for 1", 8.0),
        ("buy 2 get 1", 8.0),
        ("half price", 7.0),
        ("50% off", 8.0),
        ("percent off", 6.0),
        ("dollar off", 6.0),
        ("cents off", 5.0),
        ("rebate", 6.0),
        ("cashback", 6.0),
        ("loyalty", 5.0),
        ("rewards", 5.0),
        ("points", 4.0),
        ("member price", 6.0),
        ("club price", 6.0),
        ("bulk discount", 6.0),
        ("case discount", 6.0),
        ("family pack", 5.0),
        ("value pack", 5.0),
        ("economy size", 5.0),
        ("jumbo", 4.0),
        ("large size", 4.0),
        ("store brand", 5.0),
        ("generic", 4.0),
        ("private label", 5.0),
        ("weekly specials", 7.0),
        ("daily deals", 7.0),
        ("flash sale", 7.0),
        ("limited time", 6.0),
        ("while supplies last", 5.0),
        ("expiring soon", 5.0),
        ("closeout", 6.0),
        ("discontinued", 5.0),
        ("manager special", 6.0),
        ("reduced for quick sale", 6.0),
        ("damaged", 4.0),
        ("expired", 4.0),
        ("last chance", 5.0),
        ("final sale", 5.0)
    ]
    
    private let listManagementPatterns: [(pattern: String, weight: Double)] = [
        ("list", 8.0),
        ("add", 7.0),
        ("remove", 6.0),
        ("shopping list", 10.0),
        ("grocery list", 9.0),
        ("clear", 5.0),
        ("delete", 4.0),
        ("update", 3.0),
        ("modify", 3.0),
        ("check off", 4.0),
        ("complete", 3.0),
        ("mark done", 3.0),
        ("add to list", 8.0),
        ("remove from list", 7.0),
        ("check off list", 6.0),
        ("shopping cart", 8.0),
        ("cart", 7.0),
        ("basket", 6.0),
        ("buy", 5.0),
        ("purchase", 5.0),
        ("get", 4.0),
        ("pick up", 4.0),
        ("grab", 4.0),
        ("need", 4.0),
        ("want", 3.0),
        ("forgot", 4.0),
        ("remember", 3.0),
        ("essential", 4.0),
        ("staple", 4.0),
        ("ingredient", 5.0),
        ("supplies", 4.0),
        ("household", 4.0),
        ("personal care", 4.0),
        ("cleaning", 4.0),
        ("paper goods", 4.0),
        ("frozen foods", 5.0),
        ("fresh produce", 5.0),
        ("dairy products", 5.0),
        ("meat products", 5.0),
        ("bakery items", 5.0),
        ("beverages", 4.0),
        ("snacks", 4.0),
        ("condiments", 4.0),
        ("spices", 4.0),
        ("canned goods", 4.0),
        ("dry goods", 4.0),
        ("pantry items", 4.0)
    ]
    
    private let mealPlanningPatterns: [(pattern: String, weight: Double)] = [
        ("plan", 8.0),
        ("meal plan", 10.0),
        ("weekly", 6.0),
        ("menu", 7.0),
        ("prep", 5.0),
        ("organize", 4.0),
        ("build", 3.0),
        ("bbq", 4.0),
        ("party", 4.0),
        ("surprise", 3.0),
        ("pantry", 3.0),
        ("meal prep", 8.0),
        ("weekly menu", 9.0),
        ("dinner plan", 7.0),
        ("lunch plan", 7.0),
        ("breakfast plan", 7.0),
        ("meal planning", 9.0),
        ("weekly meals", 8.0),
        ("food prep", 7.0),
        ("cooking plan", 7.0),
        ("grocery planning", 8.0),
        ("shopping plan", 7.0),
        ("meal ideas", 6.0),
        ("dinner ideas", 6.0),
        ("lunch ideas", 6.0),
        ("breakfast ideas", 6.0),
        ("family meals", 6.0),
        ("kid friendly", 5.0),
        ("quick meals", 6.0),
        ("easy recipes", 6.0),
        ("healthy meals", 7.0),
        ("budget meals", 6.0),
        ("leftovers", 5.0),
        ("meal rotation", 5.0),
        ("seasonal meals", 6.0),
        ("special occasion", 5.0),
        ("holiday meals", 6.0),
        ("weekend cooking", 5.0),
        ("batch cooking", 6.0),
        ("freezer meals", 6.0),
        ("slow cooker", 5.0),
        ("instant pot", 5.0),
        ("one pot meals", 5.0),
        ("30 minute meals", 5.0)
    ]
    
    private let storeInfoPatterns: [(pattern: String, weight: Double)] = [
        ("store", 8.0),
        ("hours", 9.0),
        ("open", 7.0),
        ("close", 7.0),
        ("address", 8.0),
        ("phone", 6.0),
        ("location", 5.0),
        ("near", 4.0),
        ("directions", 5.0),
        ("contact", 4.0),
        ("information", 3.0),
        ("details", 3.0)
    ]
    
    private let dietaryFilterPatterns: [(pattern: String, weight: Double)] = [
        ("diet", 8.0),
        ("vegetarian", 9.0),
        ("vegan", 9.0),
        ("gluten", 8.0),
        ("allergy", 7.0),
        ("healthy", 6.0),
        ("organic", 7.0),
        ("nut", 5.0),
        ("dairy", 5.0),
        ("free", 4.0),
        ("intolerance", 6.0),
        ("restriction", 5.0),
        ("keto", 8.0),
        ("paleo", 8.0),
        ("low carb", 7.0),
        ("sugar free", 6.0),
        ("gluten-free", 9.0),
        ("dairy-free", 8.0),
        ("nut-free", 8.0),
        ("soy-free", 7.0),
        ("egg-free", 7.0),
        ("wheat-free", 8.0),
        ("lactose-free", 8.0),
        ("non-gmo", 7.0),
        ("gmo-free", 7.0),
        ("fair trade", 6.0),
        ("local", 6.0),
        ("seasonal", 6.0),
        ("whole grain", 6.0),
        ("low sodium", 7.0),
        ("low fat", 6.0),
        ("fat free", 6.0),
        ("low calorie", 6.0),
        ("high protein", 6.0),
        ("high fiber", 6.0),
        ("natural", 5.0),
        ("artificial", 4.0),
        ("preservative", 4.0),
        ("additive", 4.0),
        ("hormone free", 7.0),
        ("antibiotic free", 7.0),
        ("grass fed", 6.0),
        ("cage free", 6.0),
        ("free range", 6.0),
        ("wild caught", 6.0),
        ("farm raised", 5.0),
        ("sustainably sourced", 6.0),
        ("ethically sourced", 6.0)
    ]
    
    private let inventoryCheckPatterns: [(pattern: String, weight: Double)] = [
        ("inventory", 9.0),
        ("stock", 8.0),
        ("low", 6.0),
        ("out of stock", 10.0),
        ("on order", 8.0),
        ("discontinued", 9.0),
        ("availability", 7.0),
        ("in stock", 8.0),
        ("available", 6.0),
        ("supply", 5.0),
        ("quantity", 4.0),
        ("restock", 5.0)
    ]
    
    private let pantryManagementPatterns: [(pattern: String, weight: Double)] = [
        ("pantry", 8.0),
        ("expiring", 7.0),
        ("expired", 7.0),
        ("scan barcode", 9.0),
        ("remove expired", 8.0),
        ("add to pantry", 7.0),
        ("cabinet", 5.0),
        ("essentials", 6.0),
        ("missing", 5.0),
        ("expiration", 6.0),
        ("shelf life", 5.0),
        ("freshness", 4.0)
    ]
    
    private let sharedListPatterns: [(pattern: String, weight: Double)] = [
        ("shared list", 10.0),
        ("family", 7.0),
        ("sync", 6.0),
        ("view lists", 5.0),
        ("add item", 4.0),
        ("urgent", 5.0),
        ("collaborative", 6.0),
        ("family members", 7.0),
        ("real time", 5.0),
        ("share", 4.0),
        ("collaborate", 4.0),
        ("team", 3.0)
    ]
    
    private let budgetOptimizationPatterns: [(pattern: String, weight: Double)] = [
        ("budget", 8.0),
        ("optimize", 7.0),
        ("savings", 6.0),
        ("original cost", 8.0),
        ("discounted cost", 8.0),
        ("category", 4.0),
        ("deals", 5.0),
        ("cost estimation", 7.0),
        ("efficiency", 5.0),
        ("total cost", 6.0),
        ("spending", 5.0),
        ("money", 4.0),
        ("expensive", 4.0),
        ("cheaper", 4.0),
        ("affordable", 4.0)
    ]
    
    private let smartSuggestionsPatterns: [(pattern: String, weight: Double)] = [
        ("smart suggestions", 10.0),
        ("seasonal", 7.0),
        ("frequent", 6.0),
        ("weather", 5.0),
        ("holiday", 6.0),
        ("add all", 4.0),
        ("suggestions", 5.0),
        ("recommendations", 5.0),
        ("trending", 6.0),
        ("time based", 5.0),
        ("what can i make", 8.0),
        ("recommend", 4.0),
        ("suggest", 4.0),
        ("popular", 4.0),
        ("best", 3.0)
    ]
    
    // MARK: - Entity Patterns
    private let entityPatterns: [(type: EntityType, patterns: [String])] = [
        (.product, ["organic", "fresh", "frozen", "canned", "dried", "whole grain", "low fat", "sugar free"]),
        (.brand, ["kellogg", "kraft", "nestle", "coca cola", "pepsi", "heinz", "campbell", "general mills"]),
        (.category, ["produce", "dairy", "meat", "bakery", "frozen", "pantry", "beverages", "snacks"]),
        (.aisle, ["aisle", "section", "area", "department"]),
        (.price, ["dollar", "cent", "price", "cost", "expensive", "cheap", "budget"]),
        (.quantity, ["pound", "ounce", "gram", "kilogram", "piece", "pack", "bottle", "can"]),
        (.dietary, ["vegetarian", "vegan", "gluten-free", "dairy-free", "nut-free", "organic", "non-gmo"]),
        (.meal, ["breakfast", "lunch", "dinner", "snack", "dessert", "appetizer", "main course"]),
        (.time, ["today", "tomorrow", "week", "month", "morning", "afternoon", "evening", "night"]),
        (.location, ["store", "market", "supermarket", "grocery", "shop", "mall", "plaza"])
    ]
    
    // MARK: - Context Analysis
    private var conversationHistory: [Intent] = []
    private let maxHistorySize = 5
    
    func recognizeIntent(from query: String) -> IntentResult {
        let normalizedQuery = normalizeQuery(query)
        let context = analyzeContext(query)
        let entities = extractEntities(from: normalizedQuery)
        
        // Calculate confidence scores for each intent
        var intentScores: [(Intent, Double)] = []
        
        for intent in Intent.allCases {
            let score = calculateIntentScore(for: intent, query: normalizedQuery, context: context)
            intentScores.append((intent, score))
        }
        
        // Sort by confidence score
        intentScores.sort { $0.1 > $1.1 }
        
        let primaryIntent = intentScores.first?.0 ?? .general
        let primaryConfidence = intentScores.first?.1 ?? 0.0
        
        // Get secondary intents with confidence > 0.3
        let secondaryIntents = intentScores.dropFirst().filter { $0.1 > 0.3 }
        
        // Update conversation history
        updateConversationHistory(with: primaryIntent)
        
        return IntentResult(
            primaryIntent: primaryIntent,
            confidence: primaryConfidence,
            secondaryIntents: secondaryIntents,
            entities: entities,
            context: context
        )
    }
    
    // MARK: - Helper Methods
    
    private func normalizeQuery(_ query: String) -> String {
        return query.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    private func calculateIntentScore(for intent: Intent, query: String, context: QueryContext) -> Double {
        let patterns = getPatterns(for: intent)
        var totalScore = 0.0
        var maxPossibleScore = 0.0
        
        for (pattern, weight) in patterns {
            maxPossibleScore += weight
            
            // Exact match
            if query.contains(pattern) {
                totalScore += weight
            }
            // Fuzzy match (for typos and variations)
            else if fuzzyMatch(query: query, pattern: pattern) {
                totalScore += weight * 0.8
            }
            // Partial match
            else if query.contains(pattern.prefix(max(3, pattern.count / 2))) {
                totalScore += weight * 0.6
            }
        }
        
        // Normalize score
        let baseScore = maxPossibleScore > 0 ? totalScore / maxPossibleScore : 0.0
        
        // Apply context modifiers
        let contextModifier = calculateContextModifier(intent: intent, context: context)
        
        return min(1.0, baseScore * contextModifier)
    }
    
    private func getPatterns(for intent: Intent) -> [(pattern: String, weight: Double)] {
        switch intent {
        case .recipe: return recipePatterns
        case .productSearch: return productSearchPatterns
        case .dealSearch: return dealSearchPatterns
        case .listManagement: return listManagementPatterns
        case .mealPlanning: return mealPlanningPatterns
        case .storeInfo: return storeInfoPatterns
        case .dietaryFilter: return dietaryFilterPatterns
        case .inventoryCheck: return inventoryCheckPatterns
        case .pantryManagement: return pantryManagementPatterns
        case .sharedList: return sharedListPatterns
        case .budgetOptimization: return budgetOptimizationPatterns
        case .smartSuggestions: return smartSuggestionsPatterns
        case .general: return []
        }
    }
    
    private func fuzzyMatch(query: String, pattern: String) -> Bool {
        // Simple Levenshtein distance approximation
        let queryWords = query.components(separatedBy: .whitespaces)
        let patternWords = pattern.components(separatedBy: .whitespaces)
        
        for queryWord in queryWords {
            for patternWord in patternWords {
                if queryWord.count >= 3 && patternWord.count >= 3 {
                    let similarity = calculateSimilarity(queryWord, patternWord)
                    if similarity > 0.8 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.count == 0 {
            return 1.0
        }
        
        let distance = levenshteinDistance(longer, shorter)
        return Double(longer.count - distance) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let len1 = str1.count
        let len2 = str2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 {
            matrix[i][0] = i
        }
        
        for j in 0...len2 {
            matrix[0][j] = j
        }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = str1[str1.index(str1.startIndex, offsetBy: i - 1)] == 
                          str2[str2.index(str2.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return matrix[len1][len2]
    }
    
    private func extractEntities(from query: String) -> [Entity] {
        var entities: [Entity] = []
        
        for (type, patterns) in entityPatterns {
            for pattern in patterns {
                if let range = query.range(of: pattern) {
                    let confidence = calculateEntityConfidence(pattern: pattern, context: query)
                    entities.append(Entity(
                        type: type,
                        value: String(query[range]),
                        confidence: confidence,
                        position: range
                    ))
                }
            }
        }
        
        return entities.sorted { $0.confidence > $1.confidence }
    }
    
    private func calculateEntityConfidence(pattern: String, context: String) -> Double {
        // Base confidence based on pattern length and specificity
        var confidence = Double(pattern.count) / 20.0
        
        // Boost confidence for longer, more specific patterns
        if pattern.count > 5 {
            confidence += 0.2
        }
        
        // Reduce confidence if pattern is part of a larger word
        if context.contains(pattern + " ") || context.contains(" " + pattern) {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
    
    private func analyzeContext(_ query: String) -> QueryContext {
        let isQuestion = query.contains("?") || 
                        query.hasPrefix("what") || 
                        query.hasPrefix("where") || 
                        query.hasPrefix("when") || 
                        query.hasPrefix("how") || 
                        query.hasPrefix("why") ||
                        query.hasPrefix("can you") ||
                        query.hasPrefix("could you")
        
        let urgency: Urgency = query.contains("urgent") || query.contains("asap") || query.contains("now") ? .high :
                              query.contains("soon") || query.contains("today") ? .medium : .low
        
        let wordCount = query.components(separatedBy: .whitespaces).count
        let complexity: Complexity = wordCount > 10 ? .complex :
                                   wordCount > 5 ? .moderate : .simple
        
        return QueryContext(
            isQuestion: isQuestion,
            urgency: urgency,
            complexity: complexity,
            previousIntents: conversationHistory
        )
    }
    
    private func calculateContextModifier(intent: Intent, context: QueryContext) -> Double {
        var modifier = 1.0
        
        // Boost score for questions if intent is information-seeking
        if context.isQuestion && (intent == .productSearch || intent == .storeInfo || intent == .inventoryCheck) {
            modifier += 0.2
        }
        
        // Boost score for urgent queries
        if context.urgency == .high {
            modifier += 0.1
        }
        
        // Boost score based on conversation history
        if let lastIntent = context.previousIntents.last {
            if lastIntent == intent {
                modifier += 0.15 // Continuation of same topic
            } else if areRelatedIntents(lastIntent, intent) {
                modifier += 0.1 // Related topic
            }
        }
        
        return modifier
    }
    
    private func areRelatedIntents(_ intent1: Intent, _ intent2: Intent) -> Bool {
        let relatedGroups: [[Intent]] = [
            [.recipe, .mealPlanning, .dietaryFilter],
            [.productSearch, .dealSearch, .inventoryCheck],
            [.listManagement, .sharedList, .pantryManagement],
            [.budgetOptimization, .dealSearch, .smartSuggestions]
        ]
        
        for group in relatedGroups {
            if group.contains(intent1) && group.contains(intent2) {
                return true
            }
        }
        return false
    }
    
    private func updateConversationHistory(with intent: Intent) {
        conversationHistory.append(intent)
        if conversationHistory.count > maxHistorySize {
            conversationHistory.removeFirst()
        }
    }
    
    // MARK: - Public Helper Methods
    
    func getIntentConfidence(for intent: Intent, from query: String) -> Double {
        let result = recognizeIntent(from: query)
        if result.primaryIntent == intent {
            return result.confidence
        }
        return result.secondaryIntents.first { $0.0 == intent }?.1 ?? 0.0
    }
    
    func hasMultipleIntents(in query: String) -> Bool {
        let result = recognizeIntent(from: query)
        return result.secondaryIntents.count > 0 && result.confidence < 0.8
    }
    
    func getDetectedEntities(from query: String) -> [Entity] {
        let result = recognizeIntent(from: query)
        return result.entities
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
}

// MARK: - OpenAI Service
class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Try multiple paths to load the API key
        let possiblePaths = [
            "/Users/ethanzhang/Desktop/lumo/openai.key",  // Absolute path
            "openai.key",  // Relative to current directory
            Bundle.main.path(forResource: "openai", ofType: "key") ?? ""  // App bundle
        ]
        
        for path in possiblePaths {
            if let key = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
               !key.isEmpty && !key.hasPrefix("#") {
                self.apiKey = key
                print("[OpenAIService] API key loaded successfully from: \(path)")
                return
            }
        }
        
        self.apiKey = ""
        print("[OpenAIService] ERROR: No OpenAI API key found. Tried paths: \(possiblePaths)")
        
        // Test API key format if found
        if !self.apiKey.isEmpty {
            print("[OpenAIService] API key loaded, length: \(self.apiKey.count)")
            print("[OpenAIService] API key starts with: \(String(self.apiKey.prefix(10)))...")
        }
    }
    
    func getRecipeSuggestion(for query: String) async -> String {
        let prompt = """
        You are a helpful AI shopping assistant for a grocery store. A user is asking about recipes: "\(query)"
        
        Provide a helpful response that:
        1. Suggests relevant recipes or cooking tips
        2. Mentions ingredients they might need
        3. Offers to help them find items in the store
        4. Keeps the response friendly and conversational
        
        Keep the response under 200 words.
        """
        return await makeOpenAIRequest(prompt: prompt)
    }
    
    func getProductGuidance(for query: String) async -> String {
        let prompt = """
        You are a helpful AI shopping assistant for a grocery store. A user is looking for: "\(query)"
        
        Provide a helpful response that:
        1. Suggests where they might find this item
        2. Mentions alternative products if applicable
        3. Offers to help them locate it in the store
        4. Keeps the response friendly and helpful
        
        Keep the response under 150 words.
        """
        return await makeOpenAIRequest(prompt: prompt)
    }
    
    func getGeneralResponse(for query: String) async -> String {
        let prompt = """
        You are a helpful AI shopping assistant for a grocery store. A user asks: "\(query)"
        
        Provide a helpful response that:
        1. Answers their question if it's shopping-related
        2. Offers to help them with recipes, finding items, deals, or store information
        3. Keeps the response friendly and conversational
        4. Mentions your capabilities as a shopping assistant
        
        Keep the response under 200 words.
        """
        return await makeOpenAIRequest(prompt: prompt)
    }
    
    func getMealBuilderResponse(for query: String) async -> String {
        let prompt = """
        You are an AI Meal Builder for a grocery store app. A user wants to build meals: "\(query)"
        
        Create a comprehensive meal plan response that includes:
        
        1. **Meal Overview**: Suggest 1-3 meals based on their request (dinner for 4, weekly plan, BBQ, etc.)
        
        2. **For Each Meal Include**:
           - Dish name and brief description
           - Prep time and difficulty level
           - Estimated cost per serving
           - Dietary tags (vegetarian, gluten-free, etc.)
           - Occasion suitability (family dinner, date night, party, etc.)
        
        3. **Shopping List Integration**:
           - List all ingredients with exact quantities and measurements
           - Mention specific aisle locations (e.g., "Produce - Aisle 1", "Dairy - Aisle 3", "Meat - Aisle 5")
           - Note any substitutions for dietary restrictions or out-of-stock items
           - Calculate total estimated cost for all ingredients
           - Mention if quantities are adjusted for multiple servings
        
        4. **Smart Features**:
           - Suggest optimal meal timing and scheduling
           - Include prep-ahead tips and make-ahead options
           - Add cooking reminders and timing suggestions
           - Offer calendar integration with meal slots
           - Mention pantry check to avoid duplicate purchases
        
        5. **Special Features**:
           - "Surprise Me" mode: creative but balanced meal suggestions
           - "Build Around What I Have": suggest meals based on common pantry items
           - "Double This Recipe": scaling options for larger groups
           - Collaborative planning hints for family sharing
        
        6. **Format the response with**:
           - Clear meal sections with relevant emojis
           - Organized ingredient lists with quantities
           - Action-oriented language and next steps
           - Shopping tips and store navigation hints
           - Cooking instructions and timing guidance
        
        Make it feel like a complete meal planning experience that seamlessly integrates shopping, cooking, and scheduling. Include specific details about ingredients, locations, and timing to make it actionable.
        Keep the response detailed but well-organized (around 400-500 words).
        """
        return await makeOpenAIRequest(prompt: prompt)
    }
    
    private func makeOpenAIRequest(prompt: String) async -> String {
        guard !apiKey.isEmpty else {
            print("[OpenAIService] ERROR: API key is empty")
            return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
        }
        guard let url = URL(string: baseURL) else {
            print("[OpenAIService] ERROR: Invalid URL")
            return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
        }
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful AI shopping assistant for a grocery store. Be friendly, concise, and helpful."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OpenAIService] ERROR: Invalid HTTP response")
                return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
            }
            
            guard httpResponse.statusCode == 200 else {
                print("[OpenAIService] ERROR: HTTP \(httpResponse.statusCode)")
                return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            } else {
                return "I'm sorry, I received an unexpected response. Please try again."
            }
        } catch {
            print("OpenAI API Error: \(error)")
            return "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
        }
    }
} 