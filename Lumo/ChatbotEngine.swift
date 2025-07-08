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
        let intent = intentRecognizer.recognizeIntent(from: content)
        switch intent {
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

// MARK: - Intent Recognition
class IntentRecognizer {
    enum Intent {
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
    }
    
    func recognizeIntent(from query: String) -> Intent {
        let lowercased = query.lowercased()
        
        // Recipe-related keywords
        if lowercased.contains("recipe") || lowercased.contains("cook") || lowercased.contains("make") || 
           lowercased.contains("dish") || lowercased.contains("meal") || lowercased.contains("dinner") ||
           lowercased.contains("lunch") || lowercased.contains("breakfast") || lowercased.contains("ingredient") {
            return .recipe
        }
        
        // Product search keywords
        if lowercased.contains("find") || lowercased.contains("where") || lowercased.contains("location") ||
           lowercased.contains("aisle") || lowercased.contains("shelf") || lowercased.contains("product") ||
           lowercased.contains("item") || lowercased.contains("brand") {
            return .productSearch
        }
        
        // Deal and coupon keywords
        if lowercased.contains("deal") || lowercased.contains("coupon") || lowercased.contains("discount") ||
           lowercased.contains("sale") || lowercased.contains("offer") || lowercased.contains("save") ||
           lowercased.contains("price") || lowercased.contains("cheap") || lowercased.contains("budget") {
            return .dealSearch
        }
        
        // List management keywords
        if lowercased.contains("list") || lowercased.contains("add") || lowercased.contains("remove") ||
           lowercased.contains("shopping list") || lowercased.contains("grocery list") || lowercased.contains("clear") {
            return .listManagement
        }
        
        // Meal planning keywords
        if lowercased.contains("plan") || lowercased.contains("meal plan") || lowercased.contains("weekly") ||
           lowercased.contains("menu") || lowercased.contains("prep") || lowercased.contains("organize") ||
           lowercased.contains("build") || lowercased.contains("dinner") || lowercased.contains("lunch") ||
           lowercased.contains("breakfast") || lowercased.contains("bbq") || lowercased.contains("party") ||
           lowercased.contains("surprise") || lowercased.contains("pantry") {
            return .mealPlanning
        }
        
        // Store information keywords
        if lowercased.contains("store") || lowercased.contains("hours") || lowercased.contains("open") ||
           lowercased.contains("close") || lowercased.contains("address") || lowercased.contains("phone") ||
           lowercased.contains("location") || lowercased.contains("near") {
            return .storeInfo
        }
        
        // Dietary and health keywords
        if lowercased.contains("diet") || lowercased.contains("vegetarian") || lowercased.contains("vegan") ||
           lowercased.contains("gluten") || lowercased.contains("allergy") || lowercased.contains("healthy") ||
           lowercased.contains("organic") || lowercased.contains("nut") || lowercased.contains("dairy") {
            return .dietaryFilter
        }
        
        // Inventory check keywords
        if lowercased.contains("inventory") || lowercased.contains("stock") || lowercased.contains("low") ||
           lowercased.contains("out of stock") || lowercased.contains("on order") || lowercased.contains("discontinued") ||
           lowercased.contains("availability") || lowercased.contains("in stock") {
            return .inventoryCheck
        }
        
        // Pantry management keywords
        if lowercased.contains("pantry") || lowercased.contains("expiring") || lowercased.contains("expired") ||
           lowercased.contains("scan barcode") || lowercased.contains("remove expired") || lowercased.contains("add to pantry") ||
           lowercased.contains("cabinet") || lowercased.contains("essentials") || lowercased.contains("missing") {
            return .pantryManagement
        }
        
        // Shared list keywords
        if lowercased.contains("shared list") || lowercased.contains("family") || lowercased.contains("sync") ||
           lowercased.contains("view lists") || lowercased.contains("add item") || lowercased.contains("urgent") ||
           lowercased.contains("collaborative") || lowercased.contains("family members") || lowercased.contains("real time") {
            return .sharedList
        }
        
        // Budget optimization keywords
        if lowercased.contains("budget") || lowercased.contains("optimize") || lowercased.contains("savings") ||
           lowercased.contains("original cost") || lowercased.contains("discounted cost") || lowercased.contains("category") ||
           lowercased.contains("deals") || lowercased.contains("cost estimation") || lowercased.contains("efficiency") ||
           lowercased.contains("total cost") || lowercased.contains("spending") {
            return .budgetOptimization
        }
        
        // Smart suggestions keywords
        if lowercased.contains("smart suggestions") || lowercased.contains("seasonal") || lowercased.contains("frequent") ||
           lowercased.contains("weather") || lowercased.contains("holiday") || lowercased.contains("add all") ||
           lowercased.contains("suggestions") || lowercased.contains("recommendations") || lowercased.contains("trending") ||
           lowercased.contains("time based") || lowercased.contains("what can i make") {
            return .smartSuggestions
        }
        
        return .general
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