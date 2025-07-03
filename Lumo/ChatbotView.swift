//
//  ChatbotView.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

struct ChatbotView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatbotEngine = ChatbotEngine()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome Message
                                if chatbotEngine.messages.isEmpty {
                                    welcomeMessage
                                }
                                
                                // Chat Messages
                                ForEach(chatbotEngine.messages) { message in
                                    MessageBubble(message: message) { action in
                                        handleAction(action, for: message)
                                    }
                                }
                                
                                // Typing Indicator
                                if chatbotEngine.isTyping {
                                    TypingIndicator()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .onChange(of: chatbotEngine.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(chatbotEngine.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input Area
                    inputArea
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        chatbotEngine.clearMessages()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Welcome Message
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lumo AI Assistant")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Your smart shopping companion")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Text("Hi! I'm here to help you with:")
                .font(.subheadline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "fork.knife", title: "Recipe Guidance", description: "Find recipes and get shopping lists")
                FeatureRow(icon: "magnifyingglass", title: "Product Finder", description: "Locate items in the store")
                FeatureRow(icon: "tag", title: "Deals & Coupons", description: "Discover savings and offers")
                FeatureRow(icon: "list.bullet", title: "List Management", description: "Manage your shopping list")
                FeatureRow(icon: "clock", title: "Store Info", description: "Get store hours and navigation")
            }
            
            Text("Just ask me anything! 🛒")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .gray : .green)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
    
    // MARK: - Helper Methods
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        isInputFocused = false
        
        Task {
            await chatbotEngine.sendMessage(message)
        }
    }
    
    private func handleAction(_ action: ChatAction, for message: ChatMessage) {
        switch action {
        case .addToList:
            if let recipe = message.recipe {
                addRecipeIngredientsToList(recipe)
            } else if let product = message.product {
                addProductToList(product)
            }
        case .showAisle:
            if let recipe = message.recipe {
                showRecipeRoute(recipe)
            } else if let product = message.product {
                showProductLocation(product)
            }
        case .scaleRecipe:
            if let recipe = message.recipe {
                showRecipeScaling(recipe)
            }
        case .findAlternatives:
            if let product = message.product {
                showProductAlternatives(product)
            }
        case .clipCoupon:
            if let deal = message.deal {
                clipCoupon(deal)
            }
        case .showDeals:
            showDealsPage()
        case .navigateTo:
            showStoreNavigation()
        case .addToFavorites:
            addToFavorites(message)
        case .shareRecipe:
            if let recipe = message.recipe {
                shareRecipe(recipe)
            }
        case .filterByDiet:
            showDietaryFilters()
        case .showNutrition:
            if let product = message.product {
                showNutritionInfo(product)
            }
        case .findInStore:
            showStoreFinder()
        case .comparePrices:
            showPriceComparison()
        case .mealPlan:
            showMealPlanning()
        case .pantryCheck:
            showPantryCheck()
        case .budgetFilter:
            showBudgetFilter()
        case .timeFilter:
            showTimeFilter()
        case .allergenCheck:
            showAllergenCheck()
        case .storeInfo:
            showStoreInfo()
        case .showRecipe:
            // No-op for now
            break
        }
    }
    
    // MARK: - Action Implementations
    private func addRecipeIngredientsToList(_ recipe: Recipe) {
        // Add all recipe ingredients to the grocery list
        for ingredient in recipe.ingredients {
            _ = GroceryItem(
                name: ingredient.name,
                description: ingredient.notes ?? "",
                price: ingredient.estimatedPrice,
                category: "Produce", // You may want to map this better
                aisle: ingredient.aisle,
                brand: "",
                hasDeal: false,
                dealDescription: nil
            )
            // Add to grocery list (update this to match your actual method)
            // Example: appState.groceryList.add(groceryItem)
        }
        // Show confirmation (optional)
    }
    
    private func addProductToList(_ product: Product) {
        _ = GroceryItem(
            name: product.name,
            description: product.description,
            price: product.price,
            category: product.category,
            aisle: product.aisle,
            brand: product.brand,
            hasDeal: product.dealType != nil,
            dealDescription: product.dealType?.rawValue
        )
        // Add to grocery list (update this to match your actual method)
        // Example: appState.groceryList.add(groceryItem)
    }
    
    private func showRecipeRoute(_ recipe: Recipe) {
        // Navigate to store map with recipe route
        // This would integrate with your existing navigation system
    }
    
    private func showProductLocation(_ product: Product) {
        // Show product location on store map
    }
    
    private func showRecipeScaling(_ recipe: Recipe) {
        // Show recipe scaling options
    }
    
    private func showProductAlternatives(_ product: Product) {
        // Show alternative products
    }
    
    private func clipCoupon(_ deal: Deal) {
        // Add coupon to user's digital wallet
    }
    
    private func showDealsPage() {
        // Navigate to deals page
    }
    
    private func showStoreNavigation() {
        // Navigate to store map
    }
    
    private func addToFavorites(_ message: ChatMessage) {
        // Add item to favorites
    }
    
    private func shareRecipe(_ recipe: Recipe) {
        // Share recipe
    }
    
    private func showDietaryFilters() {
        // Show dietary filter options
    }
    
    private func showNutritionInfo(_ product: Product) {
        // Show nutrition information
    }
    
    private func showStoreFinder() {
        // Show store finder
    }
    
    private func showPriceComparison() {
        // Show price comparison
    }
    
    private func showMealPlanning() {
        // Show meal planning interface
    }
    
    private func showPantryCheck() {
        // Show pantry check interface
    }
    
    private func showBudgetFilter() {
        // Show budget filter
    }
    
    private func showTimeFilter() {
        // Show time filter
    }
    
    private func showAllergenCheck() {
        // Show allergen check
    }
    
    private func showStoreInfo() {
        // Show store information
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let onAction: (ChatAction) -> Void
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessage
            } else {
                botMessage
                Spacer()
            }
        }
    }
    
    private var userMessage: some View {
        Text(message.content)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
    }
    
    private var botMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text content
            if !message.content.isEmpty {
                Text(message.content)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            
            // Recipe response
            if let recipe = message.recipe {
                RecipeResponseView(recipe: recipe, actionButtons: message.actionButtons) { action in
                    onAction(action)
                }
            }
            
            // Product response
            if let product = message.product {
                ProductResponseView(product: product, actionButtons: message.actionButtons) { action in
                    onAction(action)
                }
            }
            
            // Deal response
            if let deal = message.deal {
                DealResponseView(deal: deal, actionButtons: message.actionButtons) { action in
                    onAction(action)
                }
            }
            
            // Action buttons only
            if message.recipe == nil && message.product == nil && message.deal == nil && !message.actionButtons.isEmpty {
                ChatActionButtonsView(buttons: message.actionButtons) { action in
                    onAction(action)
                }
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: .leading)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
        .onAppear {
            animationOffset = 0.3
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
} 