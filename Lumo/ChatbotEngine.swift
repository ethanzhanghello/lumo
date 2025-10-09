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
    private let spoonacularService = SpoonacularService.shared
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
        _ = intentResult.confidence
        
        _ = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet"),
            ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet"),
            ChatActionButton(title: "Start Route", action: .addItemToList, icon: "map")
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
    
    // MARK: - Enhanced Intent Handlers for Spec Implementation
    
    // Grocery List Management
    private func handleAddItemToList(_ query: String) async -> ChatMessage {
        // Parse item name, quantity, unit from query
        let components = parseItemFromQuery(query)
        let itemName = components.name
        let quantity = components.quantity
        let unit = components.unit
        
        guard let store = appState.selectedStore else {
            return ChatMessage(
                content: "Please select a store first to add items to your grocery list.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Choose Store", action: .addItemToList, icon: "storefront")
                ]
            )
        }
        
        // Create grocery item
        let groceryItem = GroceryItem(
            name: itemName,
            description: "Added via chatbot",
            price: estimateItemPrice(itemName),
            category: mapItemToCategory(itemName),
            aisle: mapItemToAisle(itemName),
            brand: "",
            hasDeal: false,
            dealDescription: nil
        )
        
        // Add to list
        appState.groceryList.addItem(groceryItem, store: store)
        
        let response = """
        ✅ Added **\(quantity) \(unit) \(itemName)** to your grocery list!
        
        📍 **Location**: Aisle \(groceryItem.aisle)
        💰 **Estimated Price**: $\(String(format: "%.2f", groceryItem.price))
        
        Your list now has \(appState.groceryList.totalItems) items.
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet"),
                ChatActionButton(title: "Add More", action: .addItemToList, icon: "plus.circle")
            ]
        )
    }
    
    private func handleRemoveItemFromList(_ query: String) async -> ChatMessage {
        let itemName = extractItemName(query)
        
        // Find and remove the item by name
        var removedCount = 0
        if let store = appState.selectedStore {
            let itemsToRemove = appState.groceryList.groceryItems.filter { $0.item.name.lowercased().contains(itemName.lowercased()) && $0.store.id == store.id }
            for item in itemsToRemove {
                appState.groceryList.removeItem(item.item, store: store)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            let response = """
            ✅ Removed **\(itemName)** from your grocery list.
            
            Your list now has \(appState.groceryList.totalItems) items.
            """
            
            return ChatMessage(
                content: response,
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Undo", action: .removeItemFromList, icon: "arrow.uturn.backward"),
                    ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet")
                ]
            )
        } else {
            return ChatMessage(
                content: "❌ **\(itemName)** not found in your grocery list.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet")
                ]
            )
        }
    }
    
    private func handleUpdateItemQty(_ query: String) async -> ChatMessage {
        let components = parseQuantityUpdate(query)
        let itemName = components.name
        let newQuantity = components.quantity
        
        var success = false
        if let store = appState.selectedStore {
            if let item = appState.groceryList.groceryItems.first(where: { $0.item.name.lowercased().contains(itemName.lowercased()) && $0.store.id == store.id }) {
                appState.groceryList.updateQuantity(for: item.item, store: store, to: newQuantity)
                success = true
            }
        }
        
        if success {
            let response = """
            ✅ Updated **\(itemName)** quantity to **\(newQuantity)**.
            
            Your list now has \(appState.groceryList.totalItems) items.
            """
            
            return ChatMessage(
                content: response,
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet")
                ]
            )
        } else {
            return ChatMessage(
                content: "❌ **\(itemName)** not found in your grocery list.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet")
                ]
            )
        }
    }
    
    private func handleAddRecipeToList(_ query: String) async -> ChatMessage {
        let recipeName = extractRecipeName(query)
        let servings = extractServings(query) ?? 4
        
        // Use Spoonacular API to search for recipe
        let recipes = await spoonacularService.searchRecipes(
            query: recipeName,
            number: 1
        )
        
        guard let recipe = recipes.first else {
            return ChatMessage(
                content: "❌ Recipe **\(recipeName)** not found. Try searching for a different recipe.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Search Recipes", action: .recipeSearch, icon: "magnifyingglass")
                ]
            )
        }
        
        guard let store = appState.selectedStore else {
            return ChatMessage(
                content: "Please select a store first to add recipe ingredients to your grocery list.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Choose Store", action: .addRecipeToList, icon: "storefront")
                ]
            )
        }
        
        // Scale recipe ingredients for servings and normalize
        let scaleFactor = Double(servings) / Double(recipe.servings)
        var ingredientItems: [(name: String, quantity: Int, unit: String, notes: String)] = []
        
        for ingredient in recipe.ingredients {
            let scaledAmount = ingredient.amount * scaleFactor
            let normalizedIngredient = normalizeIngredient(
                name: ingredient.name,
                amount: scaledAmount,
                unit: ingredient.unit,
                notes: "From \(recipe.name)"
            )
            ingredientItems.append(normalizedIngredient)
        }
        
        // Deduplicate ingredients
        let deduplicatedItems = deduplicateIngredients(ingredientItems)
        
        // Add to grocery list
        var addedCount = 0
        for item in deduplicatedItems {
            let groceryItem = GroceryItem(
                name: item.name,
                description: item.notes,
                price: estimateIngredientPrice(item.name),
                category: mapIngredientToCategory(item.name),
                aisle: mapIngredientToAisle(item.name),
                brand: "",
                hasDeal: false,
                dealDescription: nil
            )
            
            appState.groceryList.addItem(groceryItem, store: store, quantity: item.quantity)
            addedCount += 1
        }
        
        let response = """
        ✅ Added **\(recipe.name)** ingredients to your grocery list!
        
        📊 **Servings**: \(servings)
        🛒 **Items Added**: \(addedCount) ingredients
        💰 **Estimated Cost**: $\(String(format: "%.2f", Double(addedCount) * 3.50))
        
        Your list now has \(appState.groceryList.totalItems) items.
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet"),
                ChatActionButton(title: "Start Route", action: .addItemToList, icon: "map")
            ]
        )
    }
    
    // Meal Planning
    private func handlePlanSingleMeal(_ query: String) async -> ChatMessage {
        let components = parseMealPlanQuery(query)
        let date = components.date ?? Date()
        let mealTypeString = components.mealType ?? "dinner"
        let mealType = MealType(rawValue: mealTypeString.capitalized) ?? .dinner
        let recipeName = components.recipeName
        
        // Use Spoonacular API to search for recipe
        let recipes = await spoonacularService.searchRecipes(
            query: recipeName,
            number: 1
        )
        
        guard let recipe = recipes.first else {
            return ChatMessage(
                content: "❌ Recipe **\(recipeName)** not found. Try searching for a different recipe.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Search Recipes", action: .recipeSearch, icon: "magnifyingglass")
                ]
            )
        }
        
        // Add meal to meal plan
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: components.servings ?? recipe.servings,
            notes: components.notes
        )
        
        // Add meal to meal plan - simplified for now
        print("Adding meal: \(meal.recipeName) for \(date) - \(mealType.rawValue)")
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let response = """
        ✅ Added **\(recipe.name)** to your meal plan!
        
        📅 **Date**: \(formatter.string(from: date))
        🍽️ **Meal**: \(mealType.rawValue)
        👥 **Servings**: \(meal.servings)
        ⏱️ **Prep Time**: \(recipe.prepTime + recipe.cookTime) minutes
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "Open Meal Plan", action: .showMealPlan, icon: "calendar"),
                ChatActionButton(title: "Add Ingredients", action: .addRecipeToList, icon: "plus.circle")
            ]
        )
    }
    
    private func handlePlanWeekAutofill(_ query: String) async -> ChatMessage {
        let components = parseWeekAutofillQuery(query)
        let weekStart = components.weekStart ?? getCurrentWeekStart()
        let constraints = components.constraints
        
        // Generate meal plan using OpenAI
        let aiResponse = "Meal plan generation coming soon" // Simplified for now
        
        let response = """
        🗓️ **Weekly Meal Plan Generated**
        
        📅 **Week of**: \(formatDate(weekStart))
        👥 **People**: \(constraints.people ?? 2)
        🕒 **Max Time**: \(constraints.timePerMeal ?? 60) minutes
        💰 **Budget**: $\(constraints.budget ?? 100) per week
        🥗 **Diet**: \(constraints.diet?.joined(separator: ", ") ?? "No restrictions")
        
        \(aiResponse)
        
        Would you like me to apply this plan to your calendar and add ingredients to your grocery list?
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "Preview Plan", action: .planWeekAutofill, icon: "eye"),
                ChatActionButton(title: "Apply to Calendar", action: .planWeekAutofill, icon: "calendar.badge.plus")
            ]
        )
    }
    
    private func handleShowMealPlan(_ query: String) async -> ChatMessage {
        let date = extractDate(query) ?? Date()
        let isWeekView = query.lowercased().contains("week")
        
        if isWeekView {
            let weekStart = getWeekStart(for: date)
            // Get week plan - simplified for now
            _ = [String]()
            
            let response = "📅 **Week of**: \(formatDate(weekStart))\n\nNo meals planned for this week."
            
            return ChatMessage(
                content: response,
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Open Meal Plan", action: .showMealPlan, icon: "calendar"),
                    ChatActionButton(title: "Add Ingredients", action: .addRecipeToList, icon: "plus.circle")
                ]
            )
        } else {
            // Get day plan - simplified for now
            _ = [String]()
            
            let response = "📅 **Date**: \(formatDate(date))\n\nNo meals planned for this day."
            
            return ChatMessage(
                content: response,
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Open Meal Plan", action: .showMealPlan, icon: "calendar"),
                    ChatActionButton(title: "Add/Swap Meal", action: .planSingleMeal, icon: "plus.circle")
                ]
            )
        }
    }
    
    // Nutrition Analysis
    private func handleNutritionRecipe(_ query: String) async -> ChatMessage {
        let recipeName = extractRecipeName(query)
        let servings = extractServings(query) ?? 4
        
        // Use Spoonacular API to search for recipe
        let recipes = await spoonacularService.searchRecipes(
            query: recipeName,
            number: 1
        )
        
        guard let recipe = recipes.first else {
            return ChatMessage(
                content: "❌ Recipe **\(recipeName)** not found.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Search Recipes", action: .recipeSearch, icon: "magnifyingglass")
                ]
            )
        }
        
        // Get nutrition data from Spoonacular
        let nutritionData = await getRecipeNutrition(recipe: recipe, servings: servings)
        
        let response = """
        📊 **Nutrition for \(recipe.name)** (\(servings) servings)
        
        🔥 **Calories**: \(nutritionData.calories) per serving
        🥩 **Protein**: \(String(format: "%.1f", nutritionData.protein))g
        🍞 **Carbs**: \(String(format: "%.1f", nutritionData.carbs))g
        🧈 **Fat**: \(String(format: "%.1f", nutritionData.fat))g
        🌾 **Fiber**: \(String(format: "%.1f", nutritionData.fiber ?? 0))g
        🍯 **Sugar**: \(String(format: "%.1f", nutritionData.sugar ?? 0))g
        🧂 **Sodium**: \(nutritionData.sodium ?? 0)mg
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "Add to List", action: .addRecipeToList, icon: "plus.circle"),
                ChatActionButton(title: "Add to Meal Plan", action: .planSingleMeal, icon: "calendar")
            ]
        )
    }
    
    // Recipe Search
    private func handleRecipeSearch(_ query: String) async -> ChatMessage {
        let searchQuery = extractSearchQuery(query)
        let constraints = parseRecipeConstraints(query)
        
        // Use Spoonacular API to search recipes with constraints
        let recipes = await spoonacularService.searchRecipes(
            query: searchQuery,
            diet: constraints.diet?.first,
            maxReadyTime: constraints.maxTime,
            number: 3
        )
        
        let filteredRecipes = filterRecipesByConstraints(recipes, constraints: constraints)
        
        if filteredRecipes.isEmpty {
            return ChatMessage(
                content: "❌ No recipes found matching your criteria. Try adjusting your search terms or constraints.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Search Again", action: .recipeSearch, icon: "magnifyingglass")
                ]
            )
        }
        
        let topRecipe = filteredRecipes.first!
        let response = """
        🔍 **Recipe Search Results**
        
        **\(topRecipe.name)**
        \(topRecipe.description)
        
        ⏱️ **Time**: \(topRecipe.prepTime + topRecipe.cookTime) minutes
        👥 **Servings**: \(topRecipe.servings)
        ⭐ **Rating**: \(topRecipe.rating)/5
        💰 **Cost**: ~$\(String(format: "%.2f", estimateRecipeCost(topRecipe)))
        
        Found \(filteredRecipes.count) matching recipes.
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            recipe: topRecipe,
            actionButtons: [
                ChatActionButton(title: "Add to List", action: .addRecipeToList, icon: "plus.circle"),
                ChatActionButton(title: "Plan Meal", action: .planSingleMeal, icon: "calendar"),
                ChatActionButton(title: "See Nutrition", action: .nutritionRecipe, icon: "chart.bar")
            ]
        )
    }
    
    // Leftovers
    private func handleLeftovers(_ query: String) async -> ChatMessage {
        let availableIngredients = extractIngredients(query)
        
        if availableIngredients.isEmpty {
            return ChatMessage(
                content: "Please specify what ingredients you have available. For example: 'What can I make with chicken, rice, and vegetables?'",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
                ]
            )
        }
        
        // Use Spoonacular API to find recipes by ingredients
        let recipes = await spoonacularService.findRecipesByIngredients(
            ingredients: availableIngredients,
            ranking: 2,
            ignorePantry: true
        )
        
        if recipes.isEmpty {
            return ChatMessage(
                content: "❌ No recipes found with those ingredients. Try adding more common ingredients or check your spelling.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Try Again", action: .leftovers, icon: "arrow.clockwise")
                ]
            )
        }
        
        let topRecipe = recipes.first!
        let response = """
        🍽️ **Meal Ideas with Available Ingredients**
        
        **Available**: \(availableIngredients.joined(separator: ", "))
        
        **Top Match**: \(topRecipe.name)
        ⏱️ **Time**: \(topRecipe.totalTime) minutes
        👥 **Servings**: \(topRecipe.servings)
        ⭐ **Rating**: \(String(format: "%.1f", topRecipe.rating))/5
        
        Found \(recipes.count) matching recipes.
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            recipe: topRecipe,
            actionButtons: [
                ChatActionButton(title: "Add to List", action: .addRecipeToList, icon: "plus.circle"),
                ChatActionButton(title: "Plan Meal", action: .planSingleMeal, icon: "calendar")
            ]
        )
    }
    
    // Navigation/Routing
    private func handleStartRoute(_ query: String) async -> ChatMessage {
        guard let store = appState.selectedStore else {
            return ChatMessage(
                content: "Please select a store first to start your route.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Choose Store", action: .startRoute, icon: "storefront")
                ]
            )
        }
        
        let groceryItems = appState.groceryList.groceryItems
        if groceryItems.isEmpty {
            return ChatMessage(
                content: "Your grocery list is empty. Add some items first to start your route.",
                isUser: false,
                actionButtons: [
                    ChatActionButton(title: "Add Items", action: .addItemToList, icon: "plus.circle")
                ]
            )
        }
        
        // Generate route using RouteOptimizationManager
        let routeManager = RouteOptimizationManager.shared
        // Create a basic store layout for route generation
        _ = StoreLayout(
            storeId: store.id,
            entrance: Coordinate(x: 0, y: 0),
            exits: [Coordinate(x: 100, y: 100)],
            checkouts: [CheckoutLocation(position: Coordinate(x: 50, y: 50), type: .regular, maxItems: 10)],
            aisles: [],
            connectivityGraph: ConnectivityGraph(nodes: [], edges: []),
            mapDimensions: MapDimensions(width: 200, height: 200)
        )
        let route = try? await routeManager.generateRoute(for: appState.groceryList, in: store) ?? ShoppingRoute(storeId: store.id, waypoints: [], totalDistance: 0.0, estimatedTime: 0, optimizationStrategy: .logicalOrder, createdAt: Date())
        
        let estimatedTime = appState.groceryList.estimatedTimeMinutes
        let totalItems = appState.groceryList.totalItems
        
        let response = """
        🗺️ **Route Ready!**
        
        📍 **Store**: \(store.name)
        🛒 **Items**: \(totalItems) items
        ⏱️ **ETA**: ~\(estimatedTime) minutes
        📏 **Distance**: ~\(String(format: "%.1f", route?.totalDistance ?? 0.0)) meters
        
        Your optimized shopping route is ready to begin!
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "View Map", action: .startRoute, icon: "map"),
                ChatActionButton(title: "Mark Items Done", action: .startRoute, icon: "checkmark.circle")
            ]
        )
    }
    
    // MARK: - Helper Functions for Spec Implementation
    
    private func parseItemFromQuery(_ query: String) -> (name: String, quantity: Int, unit: String) {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        var quantity = 1
        var unit = "item"
        var name = query
        
        // Extract quantity
        for (index, word) in words.enumerated() {
            if let qty = Int(word) {
                quantity = qty
                if index + 1 < words.count {
                    unit = words[index + 1]
                    // Remove quantity and unit from name
                    let remainingWords = words.dropFirst(index + 2)
                    name = remainingWords.joined(separator: " ")
                } else {
                    let remainingWords = words.dropFirst(index + 1)
                    name = remainingWords.joined(separator: " ")
                }
                break
            }
        }
        
        return (name: name, quantity: quantity, unit: unit)
    }
    
    private func extractItemName(_ query: String) -> String {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        let removeWords = ["remove", "delete", "from", "my", "grocery", "list", "shopping"]
        let filteredWords = words.filter { !removeWords.contains($0) }
        return filteredWords.joined(separator: " ")
    }
    
    private func parseQuantityUpdate(_ query: String) -> (name: String, quantity: Int) {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        var quantity = 1
        var name = query
        
        for (index, word) in words.enumerated() {
            if let qty = Int(word) {
                quantity = qty
                let remainingWords = words.dropFirst(index + 1)
                name = remainingWords.joined(separator: " ")
                break
            }
        }
        
        return (name: name, quantity: quantity)
    }
    
    private func extractRecipeName(_ query: String) -> String {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        let removeWords = ["add", "recipe", "to", "list", "plan", "meal", "for", "servings"]
        let filteredWords = words.filter { !removeWords.contains($0) }
        return filteredWords.joined(separator: " ")
    }
    
    private func extractServings(_ query: String) -> Int? {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        for (index, word) in words.enumerated() {
            if word == "servings" && index > 0 {
                return Int(words[index - 1])
            }
            if let servings = Int(word), index + 1 < words.count && words[index + 1] == "servings" {
                return servings
            }
        }
        return nil
    }
    
    private func parseMealPlanQuery(_ query: String) -> (date: Date?, mealType: String?, recipeName: String, servings: Int?, notes: String?) {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        var date: Date?
        var mealType: String?
        var recipeName = query
        var servings: Int?
        let notes: String? = nil
        
        // Extract meal type
        let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
        for type in mealTypes {
            if words.contains(type) {
                mealType = type
                break
            }
        }
        
        // Extract date
        if words.contains("tomorrow") {
            date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else if words.contains("today") {
            date = Date()
        }
        
        // Extract servings
        servings = extractServings(query)
        
        // Clean recipe name
        let removeWords = ["add", "plan", "meal", "for", "tomorrow", "today", "breakfast", "lunch", "dinner", "snack"]
        let filteredWords = words.filter { !removeWords.contains($0) }
        recipeName = filteredWords.joined(separator: " ")
        
        return (date: date, mealType: mealType, recipeName: recipeName, servings: servings, notes: notes)
    }
    
    private func parseWeekAutofillQuery(_ query: String) -> (weekStart: Date?, constraints: MealPlanConstraints) {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        var weekStart: Date?
        var constraints = MealPlanConstraints()
        
        // Extract week start
        if words.contains("next") && words.contains("week") {
            weekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: getCurrentWeekStart())
        } else if words.contains("this") && words.contains("week") {
            weekStart = getCurrentWeekStart()
        }
        
        // Extract constraints
        for (index, word) in words.enumerated() {
            if word == "people" && index > 0 {
                constraints.people = Int(words[index - 1])
            }
            if word == "minutes" && index > 0 {
                constraints.timePerMeal = Int(words[index - 1])
            }
            if word == "dollars" || word == "$" && index > 0 {
                constraints.budget = Double(words[index - 1])
            }
        }
        
        // Extract dietary restrictions
        let diets = ["vegetarian", "vegan", "gluten-free", "keto", "paleo", "dairy-free"]
        constraints.diet = diets.filter { words.contains($0) }
        
        return (weekStart: weekStart, constraints: constraints)
    }
    
    private func extractDate(_ query: String) -> Date? {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        
        if words.contains("today") {
            return Date()
        } else if words.contains("tomorrow") {
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else if words.contains("yesterday") {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        }
        
        return nil
    }
    
    private func extractSearchQuery(_ query: String) -> String {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        let removeWords = ["find", "search", "recipes", "for", "with", "that", "are"]
        let filteredWords = words.filter { !removeWords.contains($0) }
        return filteredWords.joined(separator: " ")
    }
    
    private func parseRecipeConstraints(_ query: String) -> RecipeConstraints {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        var constraints = RecipeConstraints()
        
        // Extract time constraints
        for (index, word) in words.enumerated() {
            if word == "minutes" && index > 0 {
                constraints.maxTime = Int(words[index - 1])
            }
        }
        
        // Extract dietary constraints
        let diets = ["vegetarian", "vegan", "gluten-free", "keto", "paleo", "dairy-free"]
        constraints.diet = diets.filter { words.contains($0) }
        
        // Extract calorie constraints
        for (index, word) in words.enumerated() {
            if word == "calories" && index > 0 {
                constraints.maxCalories = Int(words[index - 1])
            }
        }
        
        return constraints
    }
    
    private func extractIngredients(_ query: String) -> [String] {
        let words = query.lowercased().components(separatedBy: .whitespaces)
        let removeWords = ["what", "can", "i", "make", "with", "using", "have", "available"]
        let filteredWords = words.filter { !removeWords.contains($0) }
        
        // Split by common separators
        let ingredientsText = filteredWords.joined(separator: " ")
        let ingredients = ingredientsText.components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return ingredients
    }
    
    private func getCurrentWeekStart() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }
    
    private func getWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatWeekMealPlan(_ weekPlan: [MealPlan], weekStart: Date) -> String {
        var response = "📅 **Weekly Meal Plan** (Week of \(formatDate(weekStart)))\n\n"
        
        for (index, dayPlan) in weekPlan.enumerated() {
            let dayDate = Calendar.current.date(byAdding: .day, value: index, to: weekStart) ?? weekStart
            let dayName = DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: dayDate) - 1]
            
            response += "**\(dayName)** (\(formatDate(dayDate))):\n"
            if dayPlan.meals.isEmpty {
                response += "  No meals planned\n"
            } else {
                for meal in dayPlan.meals {
                    response += "  • \(meal.recipeName) (\(meal.servings) servings)\n"
                }
            }
            response += "\n"
        }
        
        return response
    }
    
    private func formatDayMealPlan(_ dayPlan: MealPlan?, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        if let plan = dayPlan, !plan.meals.isEmpty {
            var response = "📅 **Meal Plan for \(formatter.string(from: date))**\n\n"
            
            for meal in plan.meals {
                response += "🍽️ **\(meal.recipeName)**\n"
                response += "   👥 Servings: \(meal.servings)\n"
                if let notes = meal.notes {
                    response += "   📝 Notes: \(notes)\n"
                }
                response += "\n"
            }
            
            return response
        } else {
            return "📅 **No meals planned for \(formatter.string(from: date))**\n\nWould you like to add some meals?"
        }
    }
    
    private func estimateItemPrice(_ itemName: String) -> Double {
        // Simple price estimation based on item type
        let name = itemName.lowercased()
        if name.contains("organic") { return 4.99 }
        if name.contains("meat") || name.contains("chicken") || name.contains("beef") { return 8.99 }
        if name.contains("fish") || name.contains("salmon") { return 12.99 }
        if name.contains("cheese") || name.contains("dairy") { return 5.99 }
        if name.contains("bread") || name.contains("pasta") { return 3.99 }
        if name.contains("vegetable") || name.contains("fruit") { return 2.99 }
        return 3.99 // Default price
    }
    
    private func estimateIngredientPrice(_ ingredient: String) -> Double {
        return estimateItemPrice(ingredient)
    }
    
    private func estimateRecipeCost(_ recipe: Recipe) -> Double {
        return Double(recipe.ingredients.count) * 3.50
    }
    
    private func mapItemToCategory(_ itemName: String) -> String {
        let name = itemName.lowercased()
        if name.contains("meat") || name.contains("chicken") || name.contains("beef") || name.contains("fish") { return "Meat & Seafood" }
        if name.contains("dairy") || name.contains("cheese") || name.contains("milk") { return "Dairy" }
        if name.contains("vegetable") || name.contains("fruit") { return "Produce" }
        if name.contains("bread") || name.contains("pasta") || name.contains("grain") { return "Bakery" }
        if name.contains("canned") || name.contains("jar") { return "Canned Goods" }
        if name.contains("frozen") { return "Frozen Foods" }
        return "General"
    }
    
    private func mapItemToAisle(_ itemName: String) -> Int {
        let name = itemName.lowercased()
        if name.contains("meat") || name.contains("chicken") || name.contains("beef") || name.contains("fish") { return 5 }
        if name.contains("dairy") || name.contains("cheese") || name.contains("milk") { return 8 }
        if name.contains("vegetable") || name.contains("fruit") { return 1 }
        if name.contains("bread") || name.contains("pasta") || name.contains("grain") { return 4 }
        if name.contains("canned") || name.contains("jar") { return 7 }
        if name.contains("frozen") { return 12 }
        return 3 // Default aisle
    }
    
    private func mapIngredientToCategory(_ ingredient: String) -> String {
        return mapItemToCategory(ingredient)
    }
    
    private func mapIngredientToAisle(_ ingredient: String) -> Int {
        return mapItemToAisle(ingredient)
    }
    
    private func filterRecipesByConstraints(_ recipes: [Recipe], constraints: RecipeConstraints) -> [Recipe] {
        return recipes.filter { recipe in
            // Filter by time
            if let maxTime = constraints.maxTime {
                if recipe.prepTime + recipe.cookTime > maxTime {
                    return false
                }
            }
            
            // Filter by dietary restrictions
            if let diet = constraints.diet, !diet.isEmpty {
                let recipeTags = recipe.tags.map { $0.lowercased() }
                let hasMatchingDiet = diet.contains { dietType in
                    recipeTags.contains { $0.contains(dietType) }
                }
                if !hasMatchingDiet {
                    return false
                }
            }
            
            return true
        }
    }
    
    private func getRecipeNutrition(recipe: Recipe, servings: Int) async -> NutritionData {
        // Get detailed recipe information with nutrition from Spoonacular
        if let detailedRecipe = await spoonacularService.getRecipeDetails(id: Int(recipe.id) ?? 0) {
            // Use Spoonacular nutrition data if available
            let nutrition = detailedRecipe.nutritionInfo
            return NutritionData(
                calories: Int(nutrition.calories ?? 0),
                protein: nutrition.protein ?? 0.0,
                carbs: nutrition.carbs ?? 0.0,
                fat: nutrition.fat ?? 0.0,
                fiber: nutrition.fiber ?? 0.0,
                sugar: nutrition.sugar ?? 0.0,
                sodium: Int(nutrition.sodium ?? 0)
            )
        }
        
        // Fallback to estimated values
        return NutritionData(
            calories: 350,
            protein: 25.0,
            carbs: 30.0,
            fat: 15.0,
            fiber: 5.0,
            sugar: 8.0,
            sodium: 600
        )
    }
    
    // MARK: - Ingredient Normalization & Deduplication
    
    private func normalizeIngredient(name: String, amount: Double, unit: String, notes: String) -> (name: String, quantity: Int, unit: String, notes: String) {
        // Normalize ingredient name (remove extra descriptors, convert to singular)
        let normalizedName = normalizeIngredientName(name)
        
        // Normalize quantity (round to reasonable values)
        let normalizedQuantity = normalizeQuantity(amount)
        
        // Normalize unit
        let normalizedUnit = normalizeUnit(unit)
        
        return (name: normalizedName, quantity: normalizedQuantity, unit: normalizedUnit, notes: notes)
    }
    
    private func normalizeIngredientName(_ name: String) -> String {
        let name = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common descriptors
        let descriptors = ["fresh", "diced", "chopped", "sliced", "minced", "grated", "crushed", "dried", "frozen", "canned", "organic", "large", "medium", "small"]
        var normalizedName = name
        
        for descriptor in descriptors {
            normalizedName = normalizedName.replacingOccurrences(of: descriptor, with: "")
        }
        
        // Convert to singular
        if normalizedName.hasSuffix("s") && normalizedName.count > 3 {
            normalizedName = String(normalizedName.dropLast())
        }
        
        return normalizedName.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
    
    private func normalizeQuantity(_ amount: Double) -> Int {
        // Round to reasonable quantities
        if amount < 0.5 {
            return 1
        } else if amount < 1.5 {
            return 1
        } else if amount < 2.5 {
            return 2
        } else if amount < 3.5 {
            return 3
        } else {
            return Int(round(amount))
        }
    }
    
    private func normalizeUnit(_ unit: String) -> String {
        let unit = unit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Standardize common units
        switch unit {
        case "cup", "cups", "c":
            return "cup"
        case "tablespoon", "tablespoons", "tbsp", "tbs":
            return "tbsp"
        case "teaspoon", "teaspoons", "tsp":
            return "tsp"
        case "pound", "pounds", "lb", "lbs":
            return "lb"
        case "ounce", "ounces", "oz":
            return "oz"
        case "clove", "cloves":
            return "clove"
        case "piece", "pieces":
            return "piece"
        case "item", "items", "", "none":
            return "item"
        default:
            return unit
        }
    }
    
    private func deduplicateIngredients(_ ingredients: [(name: String, quantity: Int, unit: String, notes: String)]) -> [(name: String, quantity: Int, unit: String, notes: String)] {
        var deduplicated: [(name: String, quantity: Int, unit: String, notes: String)] = []
        var seenIngredients: [String: Int] = [:]
        
        for ingredient in ingredients {
            let key = "\(ingredient.name)_\(ingredient.unit)"
            
            if let existingIndex = seenIngredients[key] {
                // Merge quantities
                deduplicated[existingIndex].quantity += ingredient.quantity
                deduplicated[existingIndex].notes += "; \(ingredient.notes)"
            } else {
                // Add new ingredient
                deduplicated.append(ingredient)
                seenIngredients[key] = deduplicated.count - 1
            }
        }
        
        return deduplicated
    }
    
    // MARK: - AI Response Functions
    
    private func generateRecipeWithOpenAI(query: String) async -> ChatMessage {
        let prompt = """
        You are a professional chef and nutritionist. A user is asking for: "\(query)"
        
        Please provide a complete recipe that matches their request. Include:
        1. Recipe name
        2. Brief description
        3. Prep time and cook time
        4. Number of servings
        5. Complete ingredient list with quantities
        6. Step-by-step cooking instructions
        7. Any dietary notes or substitutions
        
        Format your response as a well-structured recipe that's easy to follow.
        Keep it practical and delicious!
        """
        
        let aiResponse = await openAIService.makeOpenAIRequest(prompt: prompt)
        
        return ChatMessage(
            content: "🍽️ **AI-Generated Recipe**\n\n\(aiResponse)\n\n*This recipe was generated using AI. Tap 'Add to Cart' to add ingredients to your shopping list!*",
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "Add to Cart", action: .addToCart, icon: "cart.badge.plus"),
                ChatActionButton(title: "Find More Recipes", action: .recipeSearch, icon: "magnifyingglass"),
                ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice")
            ]
        )
    }
    
    private func getGeneralResponse(for query: String) async -> String {
        let prompt = """
        You are a helpful AI shopping assistant for a grocery store. A user asks: "\(query)"
        
        Provide a helpful response that:
        1. Answers their question if it's shopping-related
        2. Offers to help them with recipes, finding items, deals, or store information
        3. Keeps the response friendly and conversational
        4. Mentions your capabilities as a shopping assistant
        
        Keep the response under 200 words.
        """
        return await openAIService.makeOpenAIRequest(prompt: prompt)
    }
    
    private func handleGeneralQuery(_ query: String) async -> ChatMessage {
        let aiResponse = await getGeneralResponse(for: query)
        return ChatMessage(
            content: aiResponse,
            isUser: false,
            actionButtons: [
                ChatActionButton(title: "Find Recipes", action: .recipeSearch, icon: "book"),
                ChatActionButton(title: "Add to List", action: .addItemToList, icon: "plus.circle"),
                ChatActionButton(title: "Meal Plan", action: .planSingleMeal, icon: "calendar"),
                ChatActionButton(title: "Store Info", action: .startRoute, icon: "map")
            ]
        )
    }
    
    private func handleMealPlanning(_ query: String) async -> ChatMessage {
        // Enhanced AI Meal Builder functionality using Spoonacular API
        let lowercased = query.lowercased()
        
        // Hardcoded responses for specific scenarios
        if lowercased.contains("build a meal for four") || lowercased.contains("build meal for four") {
            return await getHardcodedMealForFour()
        }
        
        if lowercased.contains("allergic") && (lowercased.contains("eggs") || lowercased.contains("tree nuts")) {
            return await getHardcodedAllergyFreeMeal()
        }
        
        // Hardcoded prompts for specific meal types
        var spoonacularQuery = query
        
        if lowercased.contains("high protein") || lowercased.contains("protein meal") {
            spoonacularQuery = "high protein meal"
        } else if lowercased.contains("healthy") || lowercased.contains("healthy meal") {
            spoonacularQuery = "healthy meal"
        } else if lowercased.contains("vegetarian") || lowercased.contains("vegetarian meal") {
            spoonacularQuery = "vegetarian meal"
        } else if lowercased.contains("vegan") || lowercased.contains("vegan meal") {
            spoonacularQuery = "vegan meal"
        } else if lowercased.contains("low carb") || lowercased.contains("keto") {
            spoonacularQuery = "low carb meal"
        } else if lowercased.contains("budget") || lowercased.contains("cheap") {
            spoonacularQuery = "budget meal"
        } else if lowercased.contains("quick") || lowercased.contains("fast") {
            spoonacularQuery = "quick meal"
        } else if lowercased.contains("breakfast") {
            spoonacularQuery = "breakfast"
        } else if lowercased.contains("lunch") {
            spoonacularQuery = "lunch"
        } else if lowercased.contains("dinner") {
            spoonacularQuery = "dinner"
        }
        
        // Check for specific meal builder requests
        if lowercased.contains("build") || lowercased.contains("dinner") || lowercased.contains("lunch") ||
           lowercased.contains("breakfast") || lowercased.contains("bbq") || lowercased.contains("party") ||
           lowercased.contains("week") || lowercased.contains("plan") || lowercased.contains("surprise") ||
           lowercased.contains("pantry") || lowercased.contains("healthy") || lowercased.contains("vegetarian") ||
           lowercased.contains("vegan") || lowercased.contains("budget") || lowercased.contains("protein") ||
           lowercased.contains("quick") || lowercased.contains("fast") || lowercased.contains("keto") ||
           lowercased.contains("low carb") {
            
            // Use Spoonacular API to find recipes based on the hardcoded query
            do {
                let recipes = try await spoonacularService.searchRecipes(
                    query: spoonacularQuery,
                    diet: extractDietaryPreferences(query),
                    number: 3
                )
                
                if recipes.isEmpty {
                    // Fallback to OpenAI for recipe generation
                    print("[ChatbotEngine] No recipes found in Spoonacular, falling back to OpenAI")
                    return await generateRecipeWithOpenAI(query: query)
                }
                
                // Format the response with found recipes
                var response = "🍽️ **Found \(recipes.count) recipes for you!**\n\n"
                
                for (index, recipe) in recipes.enumerated() {
                    response += "**\(index + 1). \(recipe.name)**\n"
                    response += "⏱️ Ready in: \(recipe.prepTime + recipe.cookTime) minutes\n"
                    response += "👥 Serves: \(recipe.servings) people\n"
                    response += "⭐ Rating: \(recipe.rating)/5 (\(recipe.reviewCount) reviews)\n"
                    response += "\n"
                }
                
                response += "Tap 'Add All to Cart' to add ingredients to your shopping list!"
                
                let actionButtons = [
                    ChatActionButton(title: "Add All to Cart", action: .addToCart, icon: "cart.badge.plus"),
                    ChatActionButton(title: "View Recipe Details", action: .showIngredients, icon: "list.bullet"),
                    ChatActionButton(title: "Find More Recipes", action: .recipeSearch, icon: "magnifyingglass"),
                    ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice")
                ]
                
                return ChatMessage(
                    content: response,
                    isUser: false,
                    recipe: recipes.first, // Pass the first recipe for action handling
                    actionButtons: actionButtons
                )
                
            } catch {
                // Fallback to OpenAI for recipe generation
                print("[ChatbotEngine] Spoonacular API failed: \(error.localizedDescription)")
                return await generateRecipeWithOpenAI(query: query)
            }
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
    
    // MARK: - Hardcoded Meal Responses
    
    private func getHardcodedMealForFour() async -> ChatMessage {
        do {
            // Search for a balanced, healthy meal suitable for 4 people
            let recipes = try await spoonacularService.searchRecipes(
                query: "balanced healthy dinner",
                diet: nil,
                number: 1
            )
            
            if let recipe = recipes.first {
                let response = """
                🍽️ **Perfect Meal for Four!**
                
                **\(recipe.name)**
                ⏱️ Ready in: \(recipe.prepTime + recipe.cookTime) minutes
                👥 Serves: \(recipe.servings) people
                ⭐ Rating: \(recipe.rating)/5 (\(recipe.reviewCount) reviews)
                
                This balanced meal is perfect for a family of four! It includes a good mix of protein, vegetables, and carbohydrates to keep everyone satisfied and healthy.
                
                Tap 'Add All to Cart' to add all ingredients to your shopping list!
                """
                
                let actionButtons = [
                    ChatActionButton(title: "Add All to Cart", action: .addToCart, icon: "cart.badge.plus"),
                    ChatActionButton(title: "View Recipe Details", action: .showIngredients, icon: "list.bullet"),
                    ChatActionButton(title: "Find More Recipes", action: .recipeSearch, icon: "magnifyingglass"),
                    ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice")
                ]
                
                return ChatMessage(
                    content: response,
                    isUser: false,
                    recipe: recipe,
                    actionButtons: actionButtons
                )
            } else {
                return await generateRecipeWithOpenAI(query: "balanced healthy dinner for four people")
            }
        } catch {
            print("[ChatbotEngine] Spoonacular API failed for meal for four: \(error.localizedDescription)")
            return await generateRecipeWithOpenAI(query: "balanced healthy dinner for four people")
        }
    }
    
    private func getHardcodedAllergyFreeMeal() async -> ChatMessage {
        do {
            // Search for a meal that excludes eggs and tree nuts
            let recipes = try await spoonacularService.searchRecipes(
                query: "healthy dinner",
                diet: nil,
                number: 3
            )
            
            // Filter recipes to exclude eggs and tree nuts
            let allergyFreeRecipes = recipes.filter { recipe in
                let ingredients = recipe.ingredients.map { $0.name.lowercased() }
                let hasEggs = ingredients.contains { $0.contains("egg") }
                let hasTreeNuts = ingredients.contains { ingredient in
                    ["almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut", "macadamia", "brazil nut", "pine nut"].contains { nut in
                        ingredient.contains(nut)
                    }
                }
                return !hasEggs && !hasTreeNuts
            }
            
            if let recipe = allergyFreeRecipes.first {
                let response = """
                🍽️ **Allergy-Safe Meal Found!**
                
                **\(recipe.name)**
                ⏱️ Ready in: \(recipe.prepTime + recipe.cookTime) minutes
                👥 Serves: \(recipe.servings) people
                ⭐ Rating: \(recipe.rating)/5 (\(recipe.reviewCount) reviews)
                
                ✅ **Allergy-Safe**: This recipe contains NO eggs or tree nuts
                🥗 **Healthy**: Balanced nutrition with fresh ingredients
                👨‍👩‍👧‍👦 **Family-Friendly**: Perfect for everyone to enjoy safely
                
                Tap 'Add All to Cart' to add all ingredients to your shopping list!
                """
                
                let actionButtons = [
                    ChatActionButton(title: "Add All to Cart", action: .addToCart, icon: "cart.badge.plus"),
                    ChatActionButton(title: "View Recipe Details", action: .showIngredients, icon: "list.bullet"),
                    ChatActionButton(title: "Find More Allergy-Safe Recipes", action: .recipeSearch, icon: "magnifyingglass"),
                    ChatActionButton(title: "Surprise Me", action: .surpriseMeal, icon: "dice")
                ]
                
                return ChatMessage(
                    content: response,
                    isUser: false,
                    recipe: recipe,
                    actionButtons: actionButtons
                )
            } else {
                return await generateRecipeWithOpenAI(query: "healthy dinner recipe without eggs or tree nuts")
            }
        } catch {
            print("[ChatbotEngine] Spoonacular API failed for allergy-free meal: \(error.localizedDescription)")
            return await generateRecipeWithOpenAI(query: "healthy dinner recipe without eggs or tree nuts")
        }
    }
}

// MARK: - Supporting Data Structures for Spec Implementation

struct MealPlanConstraints {
    var people: Int?
    var timePerMeal: Int?
    var budget: Double?
    var diet: [String]?
    var intolerances: [String]?
}

struct RecipeConstraints {
    var maxTime: Int?
    var diet: [String]?
    var maxCalories: Int?
}
    
    // MARK: - Enhanced Intent Handlers
    private func handleRecipeRequest(_ query: String) async -> ChatMessage {
        let recipes = RecipeDatabase.searchRecipes(query: query)
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet"),
            ChatActionButton(title: "View List", action: .addItemToList, icon: "list.bullet"),
            ChatActionButton(title: "Start Route", action: .addItemToList, icon: "map")
        ]
        
        if let recipe = recipes.first {
            // Check inventory for ingredients
            let ingredients = recipe.ingredients.compactMap { ingredient in
                sampleGroceryItems.first { $0.name.lowercased() == ingredient.name.lowercased() }
            }
            
            var inventoryStatus = ""
            for ingredient in ingredients {
                let isAvailable = true // Simplified for now
                if !isAvailable {
                    inventoryStatus += "⚠️ \(ingredient.name) is not available\n"
                }
            }
            
            let costEstimate = 0.0 // Simplified for now
            
            let response = """
            Here's a great recipe for you! 🍳
            
            **\(recipe.name)**
            \(recipe.description)
            
            ⏱️ **Time**: \(recipe.prepTime + recipe.cookTime) minutes
            👥 **Servings**: \(recipe.servings)
            💰 **Estimated Cost**: $\(String(format: "%.2f", costEstimate))
            💸 **Savings**: $\(String(format: "%.2f", costEstimate * 0.1)) (\(String(format: "%.1f", 10.0))%)
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
            let aiResponse = "Recipe suggestion feature coming soon" // Simplified for now
            return ChatMessage(content: aiResponse, isUser: false, actionButtons: actionButtons)
        }
    }
    
    private func handleProductSearch(_ query: String) async -> ChatMessage {
        let products = DealsData.searchProducts(query: query)
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Find Route", action: .startRoute, icon: "location"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Show Deals", action: .showDeals, icon: "tag"),
            ChatActionButton(title: "Add to Favorites", action: .addToFavorites, icon: "heart"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        if let product = products.first {
            // Convert Product to GroceryItem for inventory check
            _ = GroceryItem(
                name: product.name,
                description: product.description,
                price: product.price,
                category: product.category,
                aisle: Int(product.aisle) ?? 1,
                brand: product.brand,
                hasDeal: product.dealType != "Standard",
                dealDescription: product.dealType != "Standard" ? product.dealType : nil
            )
            
            let stockStatus = "In stock" // Simplified for now
            let substitutions: [String] = [] // Simplified for now
            let budgetAlternatives: [String] = [] // Simplified for now
            
            var statusMessage = ""
            if stockStatus == "In stock" {
                statusMessage = "✅ In Stock"
            } else {
                statusMessage = "❌ Out of Stock"
            }
            
            var alternativesMessage = ""
            if !substitutions.isEmpty {
                alternativesMessage += "\n**Substitutions Available**:\n"
                alternativesMessage += substitutions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            }
            
            if !budgetAlternatives.isEmpty {
                alternativesMessage += "\n**Budget Alternatives**:\n"
                alternativesMessage += budgetAlternatives.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            }
            
            let response = """
            Found it! 📍
            
            **\(product.name)** by \(product.brand)
            📍 **Location**: Aisle \(product.aisle)
            💰 **Price**: $\(String(format: "%.2f", product.price))
            📦 **Stock**: \(statusMessage)
            
            \(product.dealType != "Standard" ? "🎉 **Deal**: \(product.dealType) - Save $\(String(format: "%.2f", product.price - (product.discountPrice ?? product.price)))" : "")
            
            \(alternativesMessage)
            """
            return ChatMessage(
                content: response,
                isUser: false,
                product: nil,
                actionButtons: actionButtons
            )
        } else {
            let aiResponse = "Product guidance feature coming soon" // Simplified for now
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
    
    
    
    private func handleDietaryFilter(_ query: String) async -> ChatMessage {
        let actionButtons = [
            ChatActionButton(title: "Vegetarian", action: .filterByDiet, icon: "leaf"),
            ChatActionButton(title: "Vegan", action: .filterByDiet, icon: "leaf.arrow.circlepath"),
            ChatActionButton(title: "Gluten-Free", action: .filterByDiet, icon: "exclamationmark.shield"),
            ChatActionButton(title: "Nut-Free", action: .allergenCheck, icon: "exclamationmark.triangle")
        ]
        // Get a dynamic response from OpenAI
        let aiResponse = "Dietary guidance feature coming soon" // Simplified for now
        return ChatMessage(
            content: aiResponse,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleInventoryCheck(_ query: String) async -> ChatMessage {
        let lowStockItems: [String] = [] // Simplified for now
        let outOfStockItems: [String] = [] // Simplified for now
        
        let actionButtons = [
            ChatActionButton(title: "View Low Stock", action: .showInventory, icon: "exclamationmark.triangle"),
            ChatActionButton(title: "Find Substitutions", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
            ChatActionButton(title: "Check Pantry", action: .pantryCheck, icon: "cabinet")
        ]
        
        var response = "📦 **Inventory Status Report**\n\n"
        
        if !lowStockItems.isEmpty {
            response += "⚠️ **Low Stock Items** (\(lowStockItems.count)):\n"
            response += lowStockItems.prefix(5).map { "• \($0)" }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if !outOfStockItems.isEmpty {
            response += "❌ **Out of Stock Items** (\(outOfStockItems.count)):\n"
            response += outOfStockItems.prefix(5).map { "• \($0)" }.joined(separator: "\n")
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
        let expiringItems: [String] = [] // Simplified for now
        let expiredItems: [String] = [] // Simplified for now
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
                return "• \(item) - expires soon"
            }.joined(separator: "\n")
            response += "\n\n"
        }
        
        if !expiredItems.isEmpty {
            response += "🚫 **Expired Items** (\(expiredItems.count)):\n"
            response += expiredItems.prefix(5).map { "• \($0)" }.joined(separator: "\n")
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
        let activeLists: [String] = [] // Simplified for now
        let urgentItems: [String] = [] // Simplified for now
        
        let actionButtons = [
            ChatActionButton(title: "View Lists", action: .showSharedLists, icon: "person.3"),
            ChatActionButton(title: "Add Item", action: .addToSharedList, icon: "plus.circle"),
            ChatActionButton(title: "Urgent Items", action: .showUrgent, icon: "exclamationmark.triangle"),
            ChatActionButton(title: "Share List", action: .shareList, icon: "square.and.arrow.up")
        ]
        
        var response = "👨‍👩‍👧‍👦 **Shared Lists**\n\n"
        
        if !activeLists.isEmpty {
            response += "📋 **Active Lists** (\(activeLists.count)):\n"
            for listName in activeLists.prefix(3) {
                response += "• \(listName)\n"
            }
            response += "\n"
        }
        
        if !urgentItems.isEmpty {
            response += "⚠️ **Urgent Items** (\(urgentItems.count)):\n"
            response += urgentItems.prefix(5).map { "• \($0)" }.joined(separator: "\n")
            response += "\n"
        }
        
        response += "👥 **Active Shared Lists**:\n"
        for listName in activeLists {
            response += "• \(listName)\n"
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleBudgetOptimization(_ query: String) async -> ChatMessage {
        let costEstimate = 0.0 // Simplified for now
        let efficiencyScore = 0.0 // Simplified for now
        
        let actionButtons = [
            ChatActionButton(title: "View Budget", action: .showBudget, icon: "dollarsign.circle"),
            ChatActionButton(title: "Optimize List", action: .optimizeBudget, icon: "chart.line.uptrend.xyaxis"),
            ChatActionButton(title: "Find Deals", action: .showDeals, icon: "tag"),
            ChatActionButton(title: "Budget Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath")
        ]
        
        let response = """
        💰 **Budget Analysis**
        
        **Current Shopping List**:
        💵 Total Cost: $\(String(format: "%.2f", costEstimate))
        💸 Savings: $\(String(format: "%.2f", costEstimate * 0.1)) (\(String(format: "%.1f", 10.0))%)
        
        **Efficiency Score**: \(Int(efficiencyScore))/100
        
        **Category Breakdown**:
        • Produce: $\(String(format: "%.2f", costEstimate * 0.3))
        • Dairy: $\(String(format: "%.2f", costEstimate * 0.2))
        • Meat: $\(String(format: "%.2f", costEstimate * 0.3))
        • Other: $\(String(format: "%.2f", costEstimate * 0.2))
        
        Would you like me to optimize your list for a specific budget?
        """
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleSmartSuggestions(_ query: String) async -> ChatMessage {
        let seasonalSuggestions: [String] = [] // Simplified for now
        let frequentSuggestions: [String] = [] // Simplified for now
        let weatherSuggestions: [String] = [] // Simplified for now
        let holidaySuggestions: [String] = [] // Simplified for now
        
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
            response += seasonalSuggestions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !frequentSuggestions.isEmpty {
            response += "🔄 **Frequent Purchases** (\(frequentSuggestions.count)):\n"
            response += frequentSuggestions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !weatherSuggestions.isEmpty {
            response += "🌤️ **Weather Based** (\(weatherSuggestions.count)):\n"
            response += weatherSuggestions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            response += "\n"
        }
        
        if !holidaySuggestions.isEmpty {
            response += "🎉 **Holiday Items** (\(holidaySuggestions.count)):\n"
            response += holidaySuggestions.prefix(3).map { "• \($0)" }.joined(separator: "\n")
            response += "\n"
        }
        
        return ChatMessage(
            content: response,
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    // MARK: - Recipe Search Helper Methods
    
    private func extractDietaryPreferences(_ query: String) -> String? {
        let lowercased = query.lowercased()
        
        if lowercased.contains("vegetarian") {
            return "vegetarian"
        } else if lowercased.contains("vegan") {
            return "vegan"
        } else if lowercased.contains("keto") {
            return "ketogenic"
        } else if lowercased.contains("paleo") {
            return "paleo"
        } else if lowercased.contains("gluten free") {
            return "gluten free"
        }
        
        return nil
    }
    
    private func extractIntolerances(_ query: String) -> String? {
        let lowercased = query.lowercased()
        
        if lowercased.contains("dairy") || lowercased.contains("lactose") {
            return "dairy"
        } else if lowercased.contains("nuts") || lowercased.contains("nut") {
            return "tree nuts"
        } else if lowercased.contains("peanut") {
            return "peanut"
        } else if lowercased.contains("soy") {
            return "soy"
        } else if lowercased.contains("egg") {
            return "egg"
        } else if lowercased.contains("shellfish") {
            return "shellfish"
        }
        
        return nil
    }
    
    private func extractMealType(_ query: String) -> String? {
        let lowercased = query.lowercased()
        
        if lowercased.contains("breakfast") {
            return "breakfast"
        } else if lowercased.contains("lunch") {
            return "lunch"
        } else if lowercased.contains("dinner") {
            return "dinner"
        } else if lowercased.contains("snack") {
            return "snack"
        } else if lowercased.contains("appetizer") {
            return "appetizer"
        } else if lowercased.contains("dessert") {
            return "dessert"
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

// MARK: - Advanced Intent Recognition
class IntentRecognizer {
    enum Intent: CaseIterable {
        case recipe
        case productSearch
        case dealSearch
        case listManagement
        case mealPlanning
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
    
    private let generalPatterns: [(pattern: String, weight: Double)] = [
        ("help", 5.0),
        ("what", 3.0),
        ("how", 3.0),
        ("where", 3.0),
        ("when", 3.0),
        ("why", 3.0),
        ("can you", 4.0),
        ("do you", 4.0),
        ("tell me", 4.0),
        ("explain", 4.0),
        ("show me", 4.0),
        ("i need", 3.0),
        ("i want", 3.0),
        ("i'm looking for", 3.0),
        ("question", 2.0),
        ("?", 1.0)
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
        case .dietaryFilter: return dietaryFilterPatterns
        case .inventoryCheck: return inventoryCheckPatterns
        case .pantryManagement: return pantryManagementPatterns
        case .sharedList: return sharedListPatterns
        case .budgetOptimization: return budgetOptimizationPatterns
        case .smartSuggestions: return smartSuggestionsPatterns
        case .general: return generalPatterns
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
        if context.isQuestion && (intent == .productSearch || intent == .inventoryCheck) {
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
    
    func makeOpenAIRequest(prompt: String) async -> String {
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
