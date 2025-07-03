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
    
    // MARK: - Message Handling
    func sendMessage(_ content: String) async {
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Process message and generate response
        let response = await processMessage(content)
        
        // Hide typing indicator and add response
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
        case .general:
            return await handleGeneralQuery(content)
        }
    }
    
    // MARK: - Intent Handlers
    private func handleRecipeRequest(_ query: String) async -> ChatMessage {
        // Search for recipes
        let recipes = RecipeDatabase.searchRecipes(query: query)
        
        if let recipe = recipes.first {
            let actionButtons = [
                ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
                ChatActionButton(title: "Show Aisle", action: .showAisle, icon: "location"),
                ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
                ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath")
            ]
            
            let response = """
            Here's a great recipe for you! 🍳
            
            **\(recipe.name)**
            \(recipe.description)
            
            ⏱️ **Time**: \(recipe.prepTime + recipe.cookTime) minutes
            👥 **Servings**: \(recipe.servings)
            💰 **Estimated Cost**: $\(String(format: "%.2f", recipe.estimatedCost))
            ⭐ **Rating**: \(recipe.rating)/5 (\(recipe.reviewCount) reviews)
            
            **Ingredients** (Aisle locations included):
            \(recipe.ingredients.map { "• \($0.displayAmount) \($0.name) (Aisle \($0.aisle))" }.joined(separator: "\n"))
            
            Would you like me to add all ingredients to your shopping list and create a route through the store?
            """
            
            return ChatMessage(
                content: response,
                isUser: false,
                recipe: recipe,
                actionButtons: actionButtons
            )
        } else {
            // Use OpenAI to suggest recipes
            let aiResponse = await openAIService.getRecipeSuggestion(for: query)
            return ChatMessage(content: aiResponse, isUser: false)
        }
    }
    
    private func handleProductSearch(_ query: String) async -> ChatMessage {
        // Search products in our catalog
        let products = DealsData.searchProducts(query: query)
        
        if let product = products.first {
            let actionButtons = [
                ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
                ChatActionButton(title: "Show Aisle", action: .showAisle, icon: "location"),
                ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath"),
                ChatActionButton(title: "Show Deals", action: .showDeals, icon: "tag")
            ]
            
            let response = """
            Found it! 📍
            
            **\(product.name)** by \(product.brand)
            📍 **Location**: Aisle \(product.aisle), \(product.shelfPosition)
            💰 **Price**: $\(String(format: "%.2f", product.price))
            📦 **Stock**: \(product.stockQty) available
            
            \(product.dealType != nil ? "🎉 **Deal**: \(product.dealType?.rawValue ?? "") - Save $\(String(format: "%.2f", product.price - (product.discountPrice ?? product.price)))" : "")
            
            \(product.stockQty <= product.lowStockThreshold ? "⚠️ **Low Stock Alert**" : "")
            """
            
            return ChatMessage(
                content: response,
                isUser: false,
                product: product,
                actionButtons: actionButtons
            )
        } else {
            // Use OpenAI for general product guidance
            let aiResponse = await openAIService.getProductGuidance(for: query)
            return ChatMessage(content: aiResponse, isUser: false)
        }
    }
    
    private func handleDealSearch(_ query: String) async -> ChatMessage {
        let deals = DealsData.getActiveDeals()
        
        if let deal = deals.first {
            let actionButtons = [
                ChatActionButton(title: "Clip Coupon", action: .clipCoupon, icon: "tag"),
                ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
                ChatActionButton(title: "Show Products", action: .showDeals, icon: "list.bullet")
            ]
            
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
                isUser: false
            )
        }
    }
    
    private func handleListManagement(_ query: String) async -> ChatMessage {
        // This would integrate with the existing grocery list system
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
        let actionButtons = [
            ChatActionButton(title: "Quick Meals", action: .mealPlan, icon: "bolt"),
            ChatActionButton(title: "Budget Meals", action: .budgetFilter, icon: "dollarsign.circle"),
            ChatActionButton(title: "Pantry Check", action: .pantryCheck, icon: "cabinet"),
            ChatActionButton(title: "30-Min Meals", action: .timeFilter, icon: "clock")
        ]
        
        return ChatMessage(
            content: "Let me help you plan your meals! I can suggest recipes based on your dietary preferences, budget, available time, or ingredients you already have. What type of meal planning are you looking for? 🍽️",
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
        
        return ChatMessage(
            content: "I can help you find products and recipes that match your dietary needs! I'll filter based on your preferences and check for allergens. What dietary restrictions should I consider? 🥗",
            isUser: false,
            actionButtons: actionButtons
        )
    }
    
    private func handleGeneralQuery(_ query: String) async -> ChatMessage {
        // Use OpenAI for general questions
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
        case general
    }
    
    func recognizeIntent(from query: String) -> Intent {
        let lowercased = query.lowercased()
        
        // Recipe-related keywords
        if lowercased.contains("recipe") || lowercased.contains("how to make") || lowercased.contains("cook") || lowercased.contains("prepare") {
            return .recipe
        }
        
        // Product search keywords
        if lowercased.contains("find") || lowercased.contains("where") || lowercased.contains("aisle") || lowercased.contains("location") {
            return .productSearch
        }
        
        // Deal-related keywords
        if lowercased.contains("deal") || lowercased.contains("sale") || lowercased.contains("discount") || lowercased.contains("coupon") {
            return .dealSearch
        }
        
        // List management keywords
        if lowercased.contains("list") || lowercased.contains("add") || lowercased.contains("remove") || lowercased.contains("shopping") {
            return .listManagement
        }
        
        // Meal planning keywords
        if lowercased.contains("meal") || lowercased.contains("plan") || lowercased.contains("pantry") || lowercased.contains("ingredients") {
            return .mealPlanning
        }
        
        // Store info keywords
        if lowercased.contains("store") || lowercased.contains("hours") || lowercased.contains("close") || lowercased.contains("location") {
            return .storeInfo
        }
        
        // Dietary keywords
        if lowercased.contains("vegetarian") || lowercased.contains("vegan") || lowercased.contains("gluten") || lowercased.contains("allergen") {
            return .dietaryFilter
        }
        
        return .general
    }
}

// MARK: - OpenAI Service
class OpenAIService {
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE" // Replace with your actual OpenAI API key
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
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
    
    private func makeOpenAIRequest(prompt: String) async -> String {
        // For now, return a mock response
        // In a real implementation, you would make an actual API call to OpenAI
        
        return "I'd be happy to help you with that! As your AI shopping assistant, I can help you find recipes, locate items in the store, find deals, manage your shopping list, and much more. What specific help do you need today? 🛒"
    }
} 