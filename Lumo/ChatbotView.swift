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
    @StateObject private var chatbotEngine: ChatbotEngine
    @State private var messageText = ""
    @State private var isInputExpanded = false
    @FocusState private var isInputFocused: Bool

    @State private var showWelcomeAnimation = false
    @State private var showConfirmation: Bool = false
    @State private var confirmationMessage: String = ""
    
    @State private var showIngredientsSheet = false
    @State private var showNutritionSheet = false
    @State private var showScaleSheet = false
    @State private var showShareSheet = false
    @State private var scaleServings: Int = 1
    @State private var shareText: String = ""
    @State private var sheetRecipe: Recipe? = nil
    @State private var sheetProduct: Product? = nil
    
    init() {
        // Initialize with a placeholder - will be updated in onAppear
        self._chatbotEngine = StateObject(wrappedValue: ChatbotEngine(appState: AppState()))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header
                    modernHeader
                    
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Welcome Message with Animation
                                if chatbotEngine.messages.isEmpty {
                                    welcomeMessage
                                        .opacity(showWelcomeAnimation ? 1 : 0)
                                        .offset(y: showWelcomeAnimation ? 0 : 20)
                                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showWelcomeAnimation)
                                }
                                
                                // Chat Messages
                                ForEach(chatbotEngine.messages) { message in
                                    ModernMessageBubble(message: message) { action in
                                        handleAction(action, for: message)
                                    }
                                    .id(message.id)
                                }
                                
                                // Typing Indicator
                                if chatbotEngine.isTyping {
                                    ModernTypingIndicator()
                                        .transition(.opacity.combined(with: .scale))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 12)
                        }

                        .onChange(of: chatbotEngine.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(chatbotEngine.messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: chatbotEngine.isTyping) { _, isTyping in
                            if isTyping {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Modern Input Bar
                    modernInputBar
                }

                if showConfirmation {
                    VStack {
                        Spacer()
                        Text(confirmationMessage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.85))
                            .cornerRadius(16)
                            .shadow(radius: 10)
                            .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.3), value: showConfirmation)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showIngredientsSheet) {
                if let recipe = sheetRecipe {
                    IngredientListSheet(recipe: recipe)
                }
            }
            .sheet(isPresented: $showNutritionSheet) {
                if let recipe = sheetRecipe {
                    NutritionSheet(recipe: recipe)
                } else if let product = sheetProduct {
                    ProductNutritionSheet(product: product)
                }
            }
            .sheet(isPresented: $showScaleSheet) {
                if let recipe = sheetRecipe {
                    ScaleRecipeSheet(recipe: recipe, servings: $scaleServings) { newServings in
                        scaleServings = newServings
                        // Optionally update recipe display or add to list
                        showConfirmationToast("Scaled recipe to \(newServings) servings!")
                        showScaleSheet = false
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [shareText])
            }
        }
        .onAppear {
            // Update the ChatbotEngine with the correct AppState
            // if chatbotEngine.appState !== appState {
            //     let newEngine = ChatbotEngine(appState: appState)
            //     newEngine.messages = chatbotEngine.messages
            //     self._chatbotEngine = StateObject(wrappedValue: newEngine)
            // }
            
            withAnimation(.easeOut(duration: 0.6)) {
                showWelcomeAnimation = true
            }
        }
    }
    
    // MARK: - Modern Header
    private var modernHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Lumo AI")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Your smart shopping companion")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: { chatbotEngine.clearMessages() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .background(
            Color.black.opacity(0.3)
                .blur(radius: 20)
        )
    }
    
    // MARK: - Welcome Message
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 24) {
            // AI Avatar and Greeting
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello! 👋")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("I'm here to make your shopping experience smarter and more enjoyable.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Feature Cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ModernFeatureCard(
                    icon: "brain.head.profile",
                    title: "AI Meal Builder",
                    description: "Complete meal plans & shopping lists",
                    gradient: [.purple, .pink]
                )
                
                ModernFeatureCard(
                    icon: "magnifyingglass",
                    title: "Product Finder",
                    description: "Locate items in the store",
                    gradient: [.blue, .purple]
                )
                
                ModernFeatureCard(
                    icon: "tag",
                    title: "Deals & Coupons",
                    description: "Discover savings and offers",
                    gradient: [.green, .teal]
                )
                
                ModernFeatureCard(
                    icon: "list.bullet",
                    title: "List Management",
                    description: "Manage your shopping list",
                    gradient: [.pink, .purple]
                )
            }
            
            // Quick Start Suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking me:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    QuickSuggestionButton(text: "Build a dinner for four") {
                        sendQuickMessage("Build a dinner for four")
                    }
                    
                    QuickSuggestionButton(text: "Plan a healthy week of meals") {
                        sendQuickMessage("Plan a healthy week of meals")
                    }
                    
                    QuickSuggestionButton(text: "Where can I find milk?") {
                        sendQuickMessage("Where can I find milk?")
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Modern Input Bar
    private var modernInputBar: some View {
        VStack(spacing: 0) {
            // Background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 56)
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Input Field
                            HStack(spacing: 12) {
                                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .focused($isInputFocused)
                                    .onSubmit {
                                        sendMessage()
                                    }
                                    .lineLimit(isInputExpanded ? 4 : 1)
                                
                                if !messageText.isEmpty {
                                    Button(action: {
                                        messageText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                isInputFocused ? Color.green.opacity(0.5) : Color.white.opacity(0.2),
                                                lineWidth: isInputFocused ? 2 : 1
                                            )
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                            
                            // Send Button
                            Button(action: sendMessage) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            messageText.isEmpty ?
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            LinearGradient(
                                                colors: [.green, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(messageText.isEmpty ? .white.opacity(0.6) : .white)
                                }
                            }
                            .disabled(messageText.isEmpty)
                            .scaleEffect(messageText.isEmpty ? 1 : 1.05)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                )
        }
    }
    
    // MARK: - Helper Methods
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        isInputFocused = false
        isInputExpanded = false
        
        Task {
            await chatbotEngine.sendMessage(message)
        }
    }
    
    private func sendQuickMessage(_ text: String) {
        messageText = text
        sendMessage()
    }
    
    private func handleAction(_ action: ChatAction, for message: ChatMessage) {
        // Debug print to see if action is received
        print("Action received: \(action) for message: \(message.content)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch action {
        case .addToList, .addToCart:
            // Add all recipe or product ingredients to grocery list
            if let recipe = message.recipe {
                var missingIngredients: [String] = []
                var addedIngredients: [String] = []
                
                for ingredient in recipe.ingredients {
                    print("Processing ingredient: \(ingredient.name)")
                    
                    // Try exact match first
                    if let matchedItem = sampleGroceryItems.first(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
                        print("Exact match found: \(matchedItem.name)")
                        appState.quickAddToGroceryList(matchedItem)
                        addedIngredients.append(matchedItem.name)
                    } else {
                        // Try partial match (e.g., "chicken breast" matches "Chicken Breast")
                        let ingredientWords = ingredient.name.lowercased().split(separator: " ")
                        if let matchedItem = sampleGroceryItems.first(where: { item in
                            let itemWords = item.name.lowercased().split(separator: " ")
                            return ingredientWords.allSatisfy { word in
                                itemWords.contains(word)
                            }
                        }) {
                            print("Partial match found: \(matchedItem.name) for \(ingredient.name)")
                            appState.quickAddToGroceryList(matchedItem)
                            addedIngredients.append(matchedItem.name)
                        } else {
                            print("No match for ingredient: \(ingredient.name)")
                            missingIngredients.append(ingredient.name)
                        }
                    }
                }
                
                print("Added ingredients: \(addedIngredients)")
                print("Missing ingredients: \(missingIngredients)")
                
                if missingIngredients.isEmpty {
                    showConfirmationToast("Added all ingredients to your grocery list!")
                } else if !addedIngredients.isEmpty {
                    showConfirmationToast("Added \(addedIngredients.joined(separator: ", ")) to your list. Some items not found: \(missingIngredients.joined(separator: ", "))")
                } else {
                    showConfirmationToast("Could not add any ingredients to your grocery list.")
                }
            } else if let product = message.product {
                print("Processing product: \(product.name)")
                if let matchedItem = sampleGroceryItems.first(where: { $0.name.lowercased() == product.name.lowercased() }) {
                    print("Matched sampleGroceryItem: \(matchedItem.name)")
                    appState.quickAddToGroceryList(matchedItem)
                    showConfirmationToast("Added \(product.name) to your grocery list!")
                } else {
                    print("No match for product: \(product.name)")
                    showConfirmationToast("Could not add \(product.name) to your grocery list.")
                }
            } else {
                // Parse ingredients from message content (for meal overviews)
                print("No recipe or product found, parsing message content for ingredients")
                let ingredients = extractIngredientsFromMessage(message.content)
                print("Extracted ingredients from message: \(ingredients)")
                
                var missingIngredients: [String] = []
                var addedIngredients: [String] = []
                
                for ingredient in ingredients {
                    print("Processing extracted ingredient: \(ingredient)")
                    
                    // Try exact match first
                    if let matchedItem = sampleGroceryItems.first(where: { $0.name.lowercased() == ingredient.lowercased() }) {
                        print("Exact match found: \(matchedItem.name)")
                        appState.quickAddToGroceryList(matchedItem)
                        addedIngredients.append(matchedItem.name)
                    } else {
                        // Try partial match with more flexible logic
                        let ingredientWords = ingredient.lowercased().split(separator: " ")
                        if let matchedItem = sampleGroceryItems.first(where: { item in
                            let itemWords = item.name.lowercased().split(separator: " ")
                            // Check if all ingredient words are found in item words
                            return ingredientWords.allSatisfy { word in
                                itemWords.contains(word) || itemWords.contains { $0.contains(word) }
                            }
                        }) {
                            print("Partial match found: \(matchedItem.name) for \(ingredient)")
                            appState.quickAddToGroceryList(matchedItem)
                            addedIngredients.append(matchedItem.name)
                        } else {
                            // Try reverse matching (item words in ingredient)
                            if let matchedItem = sampleGroceryItems.first(where: { item in
                                let itemWords = item.name.lowercased().split(separator: " ")
                                return itemWords.allSatisfy { word in
                                    ingredientWords.contains(word) || ingredientWords.contains { $0.contains(word) }
                                }
                            }) {
                                print("Reverse match found: \(matchedItem.name) for \(ingredient)")
                                appState.quickAddToGroceryList(matchedItem)
                                addedIngredients.append(matchedItem.name)
                            } else {
                                print("No match for extracted ingredient: \(ingredient)")
                                missingIngredients.append(ingredient)
                            }
                        }
                    }
                }
                
                print("Added ingredients: \(addedIngredients)")
                print("Missing ingredients: \(missingIngredients)")
                
                if missingIngredients.isEmpty && !addedIngredients.isEmpty {
                    showConfirmationToast("Added all ingredients to your grocery list!")
                } else if !addedIngredients.isEmpty {
                    showConfirmationToast("Added \(addedIngredients.joined(separator: ", ")) to your list. Some items not found: \(missingIngredients.joined(separator: ", "))")
                } else {
                    showConfirmationToast("Could not add any ingredients to your grocery list.")
                }
            }
        case .mealPlan:
            // Add recipe to today's meal plan as dinner
            if let recipe = message.recipe {
                let meal = Meal(
                    date: Date(),
                    type: .dinner,
                    recipeName: recipe.name,
                    ingredients: recipe.ingredients.map { $0.name },
                    recipe: recipe,
                    servings: recipe.servings
                )
                MealPlanManager.shared.addMeal(meal)
                showConfirmationToast("Added \(recipe.name) to your meal plan for today!")
            }
        case .addToMealPlan:
            // Add recipe to meal plan with specific date and meal type
            if let recipe = message.recipe {
                // For now, add to today's dinner, but this could be enhanced with date/meal type selection
                let meal = Meal(
                    date: Date(),
                    type: .dinner,
                    recipeName: recipe.name,
                    ingredients: recipe.ingredients.map { $0.name },
                    recipe: recipe,
                    servings: recipe.servings
                )
                MealPlanManager.shared.addMeal(meal)
                showConfirmationToast("Added \(recipe.name) to your meal plan!")
            }
        case .showAisle:
            if let recipe = message.recipe {
                showRecipeRoute(recipe)
            } else if let product = message.product {
                showProductLocation(product)
            }
        case .scaleRecipe:
            if let recipe = message.recipe {
                sheetRecipe = recipe
                scaleServings = recipe.servings
                showScaleSheet = true
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
            if let recipe = message.recipe {
                appState.addRecipeToFavorites(recipe)
                showConfirmationToast("Added \(recipe.name) to favorites!")
            } else if let product = message.product {
                appState.addProductToFavorites(product)
                showConfirmationToast("Added \(product.name) to favorites!")
            }
        case .shareRecipe:
            if let recipe = message.recipe {
                shareText = "Recipe: \(recipe.name)\n\nIngredients:\n" + recipe.ingredients.map { "- \($0.displayAmount) \($0.name)" }.joined(separator: "\n")
                showShareSheet = true
            }
        case .filterByDiet:
            showDietaryFilters()
        case .showNutrition:
            if let recipe = message.recipe {
                sheetRecipe = recipe
                showNutritionSheet = true
            } else if let product = message.product {
                sheetProduct = product
                showNutritionSheet = true
            }
        case .findInStore:
            showStoreFinder()
        case .comparePrices:
            showPriceComparison()
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
        case .showIngredients:
            if let recipe = message.recipe {
                sheetRecipe = recipe
                showIngredientsSheet = true
            }
        case .surpriseMeal:
            generateSurpriseMeal()
        case .showRecipe:
            break
        case .showUrgent:
            // Show urgent items in shared list (placeholder)
            showConfirmationToast("Showing urgent items!")
        case .shareList:
            // Share the current shared list (placeholder)
            showConfirmationToast("Shared the list!")
        case .syncStatus:
            showConfirmationToast("Sync status checked!")
        case .showBudget:
            showConfirmationToast("Showing budget!")
        case .optimizeBudget:
            showConfirmationToast("Optimizing budget!")
        case .showSeasonal:
            showConfirmationToast("Showing seasonal items!")
        case .showFrequent:
            showConfirmationToast("Showing frequent items!")
        case .showWeather:
            showConfirmationToast("Showing weather-based suggestions!")
        case .showHoliday:
            showConfirmationToast("Showing holiday items!")
        case .addAllSuggestions:
            showConfirmationToast("Added all suggestions!")
        case .scanBarcode:
            showConfirmationToast("Barcode scanner opened!")
        case .removeExpired:
            showConfirmationToast("Removed expired items!")
        case .addToPantry:
            showConfirmationToast("Added to pantry!")
        case .showSharedLists:
            showConfirmationToast("Showing shared lists!")
        case .addToSharedList:
            showConfirmationToast("Added to shared list!")
        case .showFamily:
            showConfirmationToast("Showing family members!")
        case .showInventory:
            showConfirmationToast("Showing inventory!")
        case .showPantry:
            showConfirmationToast("Showing pantry!")
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
                category: "Produce",
                aisle: ingredient.aisle,
                brand: "",
                hasDeal: false,
                dealDescription: nil
            )
        }
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
    }
    
    private func showRecipeRoute(_ recipe: Recipe) {
        // Navigate to store map with recipe route
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
    
    // MARK: - AI Meal Builder Actions
    private func addMealToCart(_ message: ChatMessage) {
        // Add all meal ingredients to shopping cart
        // This would integrate with the shopping cart system
        print("Adding meal ingredients to cart...")
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func showMealIngredients(_ message: ChatMessage) {
        // Show detailed ingredient breakdown with quantities and aisle locations
        print("Showing meal ingredients breakdown...")
    }
    
    private func generateSurpriseMeal() {
        // Generate a random meal suggestion
        Task {
            await chatbotEngine.sendMessage("Surprise me with a random meal")
        }
    }

    private func showConfirmationToast(_ message: String) {
        confirmationMessage = message
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showConfirmation = false
        }
    }
    
    private func extractIngredientsFromMessage(_ content: String) -> [String] {
        var ingredients: [String] = []
        
        // Common ingredient keywords to look for
        let ingredientKeywords = [
            "chicken", "beef", "pork", "salmon", "shrimp", "fish",
            "rice", "pasta", "bread", "flour", "sugar", "salt", "pepper",
            "onion", "garlic", "tomato", "lettuce", "spinach", "carrot",
            "potato", "broccoli", "bell pepper", "mushroom", "zucchini",
            "milk", "cheese", "yogurt", "butter", "cream", "egg",
            "olive oil", "vegetable oil", "vinegar", "lemon", "lime",
            "herb", "spice", "sauce", "stock", "broth", "wine",
            "nut", "seed", "bean", "lentil", "quinoa", "oat",
            "banana", "apple", "orange", "berry", "grape", "avocado",
            "bbq sauce", "bell peppers", "red onion", "asparagus", "quinoa",
            "black beans", "corn", "lemon", "herbs", "vegetables"
        ]
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Look for lines that contain ingredient keywords
            for keyword in ingredientKeywords {
                if lowercasedLine.contains(keyword) {
                    // Extract the ingredient name from the line
                    if let ingredient = extractIngredientFromLine(line, keyword: keyword) {
                        // Clean up the ingredient name
                        let cleanedIngredient = cleanIngredientName(ingredient)
                        if !cleanedIngredient.isEmpty {
                            ingredients.append(cleanedIngredient)
                        }
                    }
                }
            }
        }
        
        // If no ingredients found, try to infer common ingredients based on dish names
        if ingredients.isEmpty {
            ingredients = inferIngredientsFromDishNames(content)
        }
        
        // Remove duplicates and return
        return Array(Set(ingredients))
    }
    
    private func extractIngredientFromLine(_ line: String, keyword: String) -> String? {
        // Look for patterns like "• chicken breast", "- chicken breast", "chicken breast"
        let patterns = [
            "•\\s*([^\\n]+)",  // • ingredient
            "-\\s*([^\\n]+)",  // - ingredient
            "\\*\\s*([^\\n]+)", // * ingredient
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: line) {
                    let ingredient = String(line[swiftRange]).trimmingCharacters(in: .whitespaces)
                    if ingredient.lowercased().contains(keyword) {
                        return ingredient
                    }
                }
            }
        }
        
        // If no pattern match, try to extract the keyword with surrounding context
        let words = line.components(separatedBy: .whitespaces)
        for (index, word) in words.enumerated() {
            if word.lowercased().contains(keyword) {
                // Try to get 2-3 words around the keyword
                let start = max(0, index - 1)
                let end = min(words.count, index + 2)
                let ingredientWords = Array(words[start..<end])
                return ingredientWords.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private func cleanIngredientName(_ ingredient: String) -> String {
        var cleaned = ingredient
        
        // Remove common prefixes and suffixes
        let prefixesToRemove = ["**", "*", "-", "•", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        let suffixesToRemove = ["**", "*", ":", "|", "Easy", "Medium", "Hard", "minutes", "min", "serving", "servings"]
        
        for prefix in prefixesToRemove {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        for suffix in suffixesToRemove {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove quantities and measurements
        let quantityPatterns = [
            "\\d+\\s*(lbs?|oz|g|kg|ml|l|cup|cups|tbsp|tsp|slice|slices|clove|cloves|whole|medium|large|small)",
            "\\d+\\s*",
            "\\d+"
        ]
        
        for pattern in quantityPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Clean up extra whitespace and punctuation
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove if it's too short or contains obvious non-ingredient text
        if cleaned.count < 2 || cleaned.contains("**") || cleaned.contains("Description") || cleaned.contains("Prep Time") {
            return ""
        }
        
        return cleaned
    }
    
    private func inferIngredientsFromDishNames(_ content: String) -> [String] {
        var inferredIngredients: [String] = []
        let lowercasedContent = content.lowercased()
        
        // Common dish-to-ingredient mappings
        let dishIngredientMappings: [String: [String]] = [
            "chicken": ["chicken breast", "olive oil", "lemon", "herbs", "salt", "pepper"],
            "salmon": ["salmon", "olive oil", "lemon", "salt", "pepper"],
            "quinoa": ["quinoa", "bell peppers", "black beans", "corn", "olive oil"],
            "bell peppers": ["bell peppers", "quinoa", "black beans", "corn", "olive oil"],
            "asparagus": ["asparagus", "olive oil", "salt", "pepper"],
            "vegetables": ["bell peppers", "carrots", "broccoli", "olive oil"],
            "grilled": ["olive oil", "salt", "pepper"],
            "roasted": ["olive oil", "salt", "pepper"],
            "herb": ["herbs", "olive oil", "salt", "pepper"],
            "lemon": ["lemon", "olive oil", "salt", "pepper"]
        ]
        
        // Check for dish keywords and add corresponding ingredients
        for (dishKeyword, ingredients) in dishIngredientMappings {
            if lowercasedContent.contains(dishKeyword) {
                inferredIngredients.append(contentsOf: ingredients)
            }
        }
        
        // Add common cooking ingredients that are likely needed
        if lowercasedContent.contains("grilled") || lowercasedContent.contains("roasted") {
            inferredIngredients.append(contentsOf: ["olive oil", "salt", "pepper"])
        }
        
        if lowercasedContent.contains("chicken") {
            inferredIngredients.append("chicken breast")
        }
        
        if lowercasedContent.contains("salmon") {
            inferredIngredients.append("salmon")
        }
        
        if lowercasedContent.contains("quinoa") {
            inferredIngredients.append("quinoa")
        }
        
        if lowercasedContent.contains("bell peppers") {
            inferredIngredients.append("bell peppers")
        }
        
        if lowercasedContent.contains("asparagus") {
            inferredIngredients.append("asparagus")
        }
        
        return Array(Set(inferredIngredients))
    }
}

// MARK: - Modern Message Bubble
struct ModernMessageBubble: View {
    let message: ChatMessage
    let onAction: (ChatAction) -> Void
    @State private var showContent = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 60)
                userMessage
            } else {
                botMessage
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                showContent = true
            }
        }
    }
    
    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(message.content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.green.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : 20)
            
            Text(formatTime(message.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    private var botMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            // AI Avatar
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Lumo AI")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Message Content
            VStack(alignment: .leading, spacing: 16) {
                // Text content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                }
                
                // Smart Cards
                if let recipe = message.recipe {
                    ModernRecipeCard(recipe: recipe, actionButtons: message.actionButtons) { action in
                        onAction(action)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                
                if let product = message.product {
                    ModernProductCard(product: product, actionButtons: message.actionButtons) { action in
                        onAction(action)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                
                if let deal = message.deal {
                    ModernDealCard(deal: deal, actionButtons: message.actionButtons) { action in
                        onAction(action)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                
                // Action buttons only
                if message.recipe == nil && message.product == nil && message.deal == nil && !message.actionButtons.isEmpty {
                    ModernActionButtonsView(buttons: message.actionButtons) { action in
                        onAction(action)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: .leading)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Modern Typing Indicator
struct ModernTypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.8), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
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
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .id("typing")
        .onAppear {
            animationOffset = 0.3
        }
    }
}

// MARK: - Modern Feature Card
struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Suggestion Button
struct QuickSuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
} 

// MARK: - Ingredient List Sheet
struct IngredientListSheet: View {
    let recipe: Recipe
    var body: some View {
        NavigationView {
            List(recipe.ingredients, id: \ .id) { ing in
                VStack(alignment: .leading) {
                    Text("\(ing.displayAmount) \(ing.name)")
                        .font(.headline)
                    if let notes = ing.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Text("Aisle: \(ing.aisle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Ingredients")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Nutrition Sheet
struct NutritionSheet: View {
    let recipe: Recipe
    var body: some View {
        VStack(spacing: 16) {
            Text(recipe.name)
                .font(.title2)
                .bold()
            Text("Calories: \(recipe.nutritionInfo.calories)")
            Text("Protein: \(recipe.nutritionInfo.protein, specifier: "%.1f")g")
            Text("Carbs: \(recipe.nutritionInfo.carbs, specifier: "%.1f")g")
            Text("Fat: \(recipe.nutritionInfo.fat, specifier: "%.1f")g")
            if let fiber = recipe.nutritionInfo.fiber {
                Text("Fiber: \(fiber, specifier: "%.1f")g")
            }
            if let sugar = recipe.nutritionInfo.sugar {
                Text("Sugar: \(sugar, specifier: "%.1f")g")
            }
            if let sodium = recipe.nutritionInfo.sodium {
                Text("Sodium: \(sodium)mg")
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Product Nutrition Sheet
struct ProductNutritionSheet: View {
    let product: Product
    var body: some View {
        VStack(spacing: 16) {
            Text(product.name)
                .font(.title2)
                .bold()
            // Add product nutrition info here if available
            Text("Nutrition info not available.")
            Spacer()
        }
        .padding()
    }
}

// MARK: - Scale Recipe Sheet
struct ScaleRecipeSheet: View {
    let recipe: Recipe
    @Binding var servings: Int
    var onScale: (Int) -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("Scale Recipe")
                .font(.title2)
                .bold()
            Stepper("Servings: \(servings)", value: $servings, in: 1...20)
            Button("Scale") {
                onScale(servings)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Activity View (Share Sheet)
import UIKit
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 