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
        case .general:
            return await handleGeneralQuery(content)
        }
    }
    
    // MARK: - Intent Handlers
    private func handleRecipeRequest(_ query: String) async -> ChatMessage {
        let recipes = RecipeDatabase.searchRecipes(query: query)
        let actionButtons = [
            ChatActionButton(title: "Add to List", action: .addToList, icon: "plus.circle"),
            ChatActionButton(title: "Show Aisle", action: .showAisle, icon: "location"),
            ChatActionButton(title: "Scale Recipe", action: .scaleRecipe, icon: "arrow.up.arrow.down"),
            ChatActionButton(title: "Find Alternatives", action: .findAlternatives, icon: "arrow.triangle.2.circlepath")
        ]
        if let recipe = recipes.first {
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
            ChatActionButton(title: "Show Deals", action: .showDeals, icon: "tag")
        ]
        if let product = products.first {
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