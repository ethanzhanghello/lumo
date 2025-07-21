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
    
    // Enhanced meal planning states
    @State private var showMealPlanningSheet = false
    @State private var selectedRecipeForPlanning: Recipe? = nil
    @State private var selectedDate = Date()
    @State private var selectedMealType: MealType = .dinner
    @State private var selectedServings = 2
    @State private var showBatchPlanningSheet = false
    @State private var batchMeals: [BatchMealSelection] = []
    
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
            .sheet(isPresented: $showMealPlanningSheet) {
                if let recipe = selectedRecipeForPlanning {
                    EnhancedMealPlanningSheet(
                        recipe: recipe,
                        selectedDate: $selectedDate,
                        selectedMealType: $selectedMealType,
                        selectedServings: $selectedServings,
                        onConfirm: {
                            addMealToPlan(recipe: recipe, date: selectedDate, mealType: selectedMealType, servings: selectedServings)
                            showMealPlanningSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showBatchPlanningSheet) {
                if let recipe = selectedRecipeForPlanning {
                    BatchMealPlanningSheet(
                        recipe: recipe,
                        batchMeals: $batchMeals,
                        onConfirm: {
                            addBatchMealsToPlan()
                            showBatchPlanningSheet = false
                        }
                    )
                }
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
        case .addToList:
            if let recipe = message.recipe {
                // Enhanced ingredient addition with better feedback
                var addedIngredients: [String] = []
                var missingIngredients: [String] = []
                
                for ingredient in recipe.ingredients {
                    // Try to find matching grocery item
                    if let groceryItem = sampleGroceryItems.first(where: { item in
                        item.name.lowercased().contains(ingredient.name.lowercased()) ||
                        ingredient.name.lowercased().contains(item.name.lowercased())
                    }) {
                        let scaledAmount = ingredient.amount * (Double(selectedServings) / Double(recipe.servings))
                        let itemToAdd = GroceryItem(
                            name: ingredient.name,
                            description: "\(scaledAmount) \(ingredient.unit) - from \(recipe.name)",
                            price: groceryItem.price,
                            category: groceryItem.category,
                            aisle: groceryItem.aisle,
                            brand: groceryItem.brand,
                            hasDeal: groceryItem.hasDeal,
                            dealDescription: groceryItem.dealDescription
                        )
                        if let store = appState.selectedStore {
                            appState.groceryList.addItem(itemToAdd, store: store)
                            addedIngredients.append(ingredient.name)
                        }
                    } else {
                        missingIngredients.append(ingredient.name)
                    }
                }
                
                print("Added ingredients: \(addedIngredients)")
                print("Missing ingredients: \(missingIngredients)")
                
                if missingIngredients.isEmpty && !addedIngredients.isEmpty {
                    showConfirmationToast("Added all \(addedIngredients.count) ingredients to your grocery list!")
                } else if !addedIngredients.isEmpty {
                    showConfirmationToast("Added \(addedIngredients.count) ingredients. \(missingIngredients.count) items need manual addition.")
                } else {
                    showConfirmationToast("Could not add any ingredients automatically. Please add manually.")
                }
            }
            
        case .mealPlan, .addToMealPlan:
            // Enhanced meal planning with date/time selection
            if let recipe = message.recipe {
                selectedRecipeForPlanning = recipe
                selectedDate = Date()
                selectedMealType = .dinner
                selectedServings = recipe.servings
                showMealPlanningSheet = true
            } else {
                showConfirmationToast("No recipe found to add to meal plan")
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
            if let recipe = message.recipe {
                // Show detailed recipe view
                sheetRecipe = recipe
                showIngredientsSheet = true
            }
            
        // Enhanced batch planning action
        case .addToCart:
            if let recipe = message.recipe {
                // Add recipe ingredients to grocery list
                addRecipeIngredientsToGroceryList(recipe)
            } else {
                // Parse ingredients from AI-generated text and add to grocery list
                addIngredientsFromTextToGroceryList(message.content)
            }
            
        // Add missing cases
        case .showInventory:
            showConfirmationToast("Showing inventory!")
            
        case .showPantry:
            showConfirmationToast("Showing pantry!")
            
        case .scanBarcode:
            showConfirmationToast("Opening barcode scanner!")
            
        case .removeExpired:
            showConfirmationToast("Removing expired items!")
            
        case .addToPantry:
            showConfirmationToast("Adding to pantry!")
            
        case .showSharedLists:
            showConfirmationToast("Showing shared lists!")
            
        case .addToSharedList:
            showConfirmationToast("Adding to shared list!")
            
        case .showFamily:
            showConfirmationToast("Showing family members!")
            
        case .showUrgent:
            showConfirmationToast("Showing urgent items!")
            
        case .shareList:
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
            showConfirmationToast("Adding all suggestions!")
        }
    }
    
    // MARK: - Action Implementations
    private func addRecipeIngredientsToGroceryList(_ recipe: Recipe) {
        guard let store = appState.selectedStore else {
            showConfirmationToast("Please select a store first!")
            return
        }
        
        var addedCount = 0
        
        // Add all recipe ingredients to the grocery list
        for ingredient in recipe.ingredients {
            let groceryItem = GroceryItem(
                name: ingredient.name,
                description: ingredient.notes ?? "From \(recipe.name)",
                price: ingredient.estimatedPrice,
                category: mapIngredientToCategory(ingredient.name),
                aisle: ingredient.aisle,
                brand: "",
                hasDeal: false,
                dealDescription: nil
            )
            
            appState.groceryList.addItem(groceryItem, store: store)
            addedCount += 1
        }
        
        showConfirmationToast("Added \(addedCount) ingredients to your grocery list!")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func addIngredientsFromTextToGroceryList(_ content: String) {
        guard let store = appState.selectedStore else {
            showConfirmationToast("Please select a store first!")
            return
        }
        
        let ingredients = extractIngredientsFromMessage(content)
        var addedCount = 0
        
        for ingredient in ingredients {
            let groceryItem = GroceryItem(
                name: ingredient,
                description: "From AI meal plan",
                price: estimateIngredientPrice(ingredient),
                category: mapIngredientToCategory(ingredient),
                aisle: mapIngredientToAisle(ingredient),
                brand: "",
                hasDeal: false,
                dealDescription: nil
            )
            
            appState.groceryList.addItem(groceryItem, store: store)
            addedCount += 1
        }
        
        if addedCount > 0 {
            showConfirmationToast("Added \(addedCount) ingredients to your grocery list!")
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } else {
            showConfirmationToast("No ingredients found to add.")
        }
    }
    
    private func mapIngredientToCategory(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("pork") || lowercased.contains("salmon") || lowercased.contains("fish") || lowercased.contains("meat") {
            return "Meat & Seafood"
        } else if lowercased.contains("onion") || lowercased.contains("garlic") || lowercased.contains("tomato") || lowercased.contains("lettuce") || lowercased.contains("pepper") || lowercased.contains("herb") {
            return "Produce"
        } else if lowercased.contains("milk") || lowercased.contains("cheese") || lowercased.contains("yogurt") || lowercased.contains("butter") || lowercased.contains("cream") {
            return "Dairy"
        } else if lowercased.contains("pasta") || lowercased.contains("rice") || lowercased.contains("bread") || lowercased.contains("flour") {
            return "Pantry"
        } else if lowercased.contains("oil") || lowercased.contains("sauce") || lowercased.contains("spice") || lowercased.contains("oregano") || lowercased.contains("salt") || lowercased.contains("pepper") {
            return "Condiments & Spices"
        } else {
            return "Grocery"
        }
    }
    
    private func mapIngredientToAisle(_ ingredient: String) -> Int {
        let lowercased = ingredient.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("pork") || lowercased.contains("salmon") || lowercased.contains("fish") || lowercased.contains("meat") {
            return 5  // Meat aisle
        } else if lowercased.contains("onion") || lowercased.contains("garlic") || lowercased.contains("tomato") || lowercased.contains("lettuce") || lowercased.contains("pepper") || lowercased.contains("herb") {
            return 1  // Produce aisle
        } else if lowercased.contains("milk") || lowercased.contains("cheese") || lowercased.contains("yogurt") || lowercased.contains("butter") || lowercased.contains("cream") {
            return 3  // Dairy aisle
        } else if lowercased.contains("pasta") || lowercased.contains("rice") || lowercased.contains("bread") || lowercased.contains("flour") {
            return 4  // Pantry aisle
        } else {
            return 2  // Default aisle
        }
    }
    
    private func estimateIngredientPrice(_ ingredient: String) -> Double {
        let lowercased = ingredient.lowercased()
        
        if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("pork") || lowercased.contains("salmon") || lowercased.contains("fish") || lowercased.contains("meat") {
            return 8.99  // Meat prices
        } else if lowercased.contains("cheese") {
            return 4.99
        } else if lowercased.contains("pasta") || lowercased.contains("rice") {
            return 2.49
        } else if lowercased.contains("sauce") || lowercased.contains("oil") {
            return 3.99
        } else {
            return 2.99  // Default price
        }
    }
    
    private func addProductToList(_ product: Product) {
        _ = GroceryItem(
            name: product.name,
            description: product.description ?? "No description available",
            price: product.basePrice,
            category: product.category,
            aisle: 1, // Default aisle since Product doesn't have aisle property
            brand: product.brand ?? "Generic",
            hasDeal: false, // Product doesn't have dealType property
            dealDescription: nil
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
    
    // MARK: - Enhanced Helper Functions
    
    private func addMealToPlan(recipe: Recipe, date: Date, mealType: MealType, servings: Int) {
        let meal = Meal(
            date: date,
            type: mealType,
            recipeName: recipe.name,
            ingredients: recipe.ingredients.map { $0.name },
            recipe: recipe,
            servings: servings
        )
        
        MealPlanManager.shared.addMeal(meal)
        
        // Enhanced feedback with specific details
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: date)
        
        showConfirmationToast("Added \(recipe.name) to \(mealType.rawValue.lowercased()) on \(dateString)!")
        
        // Haptic feedback for success
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func addBatchMealsToPlan() {
        var addedCount = 0
        
        for batchMeal in batchMeals {
            guard let recipe = selectedRecipeForPlanning else { continue }
            
            let meal = Meal(
                date: batchMeal.date,
                type: batchMeal.mealType,
                recipeName: recipe.name,
                ingredients: recipe.ingredients.map { $0.name },
                recipe: recipe,
                servings: batchMeal.servings
            )
            
            MealPlanManager.shared.addMeal(meal)
            addedCount += 1
        }
        
        showConfirmationToast("Added \(addedCount) meals to your meal plan!")
        
        // Clear batch selections
        batchMeals = []
        
        // Haptic feedback for success
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
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
            Text("Calories: \(recipe.nutritionInfo.calories ?? 0)")
            Text("Protein: \(recipe.nutritionInfo.protein ?? 0.0, specifier: "%.1f")g")
            Text("Carbs: \(recipe.nutritionInfo.carbs ?? 0.0, specifier: "%.1f")g")
            Text("Fat: \(recipe.nutritionInfo.fat ?? 0.0, specifier: "%.1f")g")
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let nutrition = product.nutritionInfo {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nutrition Facts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    NutritionRow(label: "Calories", value: "\(nutrition.calories ?? 0)")
                                    NutritionRow(label: "Protein", value: String(format: "%.1f", nutrition.protein ?? 0.0) + "g")
                                    NutritionRow(label: "Carbs", value: String(format: "%.1f", nutrition.carbs ?? 0.0) + "g")
                                    NutritionRow(label: "Fat", value: String(format: "%.1f", nutrition.fat ?? 0.0) + "g")
                                    if let fiber = nutrition.fiber {
                                        NutritionRow(label: "Fiber", value: String(format: "%.1f", fiber) + "g")
                                    }
                                    if let sugar = nutrition.sugar {
                                        NutritionRow(label: "Sugar", value: String(format: "%.1f", sugar) + "g")
                                    }
                                    if let sodium = nutrition.sodium {
                                        NutritionRow(label: "Sodium", value: "\(sodium)mg")
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        } else {
                            Text("Nutrition information not available")
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
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

// MARK: - Enhanced Meal Planning Sheet
struct EnhancedMealPlanningSheet: View {
    let recipe: Recipe
    @Binding var selectedDate: Date
    @Binding var selectedMealType: MealType
    @Binding var selectedServings: Int
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Recipe Preview
                        recipePreviewSection
                        
                        // Date Selection
                        dateSelectionSection
                        
                        // Meal Type Selection
                        mealTypeSelectionSection
                        
                        // Servings Selection
                        servingsSelectionSection
                        
                        // Confirm Button
                        confirmButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add to Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { onConfirm() }
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
            )
        }
    }
    
    private var recipePreviewSection: some View {
        VStack(spacing: 12) {
            Text(recipe.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(recipe.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                InfoChip(icon: "clock", text: "\(recipe.totalTime) min")
                InfoChip(icon: "person.2", text: "\(recipe.servings) servings")
                InfoChip(icon: "star.fill", text: String(format: "%.1f", recipe.rating))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .colorScheme(.dark)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealTypeSelectionCard(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    ) {
                        selectedMealType = mealType
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var servingsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if selectedServings > 1 {
                        selectedServings -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(selectedServings > 1 ? .lumoGreen : .gray)
                }
                .disabled(selectedServings <= 1)
                
                Spacer()
                
                Text("\(selectedServings)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    if selectedServings < 12 {
                        selectedServings += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(selectedServings < 12 ? .lumoGreen : .gray)
                }
                .disabled(selectedServings >= 12)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var confirmButton: some View {
        Button(action: onConfirm) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                
                Text("Add to Meal Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.lumoGreen, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Batch Meal Planning Sheet
struct BatchMealPlanningSheet: View {
    let recipe: Recipe
    @Binding var batchMeals: [BatchMealSelection]
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDates: Set<Date> = []
    @State private var selectedMealTypes: Set<MealType> = [.dinner]
    @State private var defaultServings = 2
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Quick Selection Buttons
                        quickSelectionSection
                        
                        // Date Range Selection
                        dateRangeSection
                        
                        // Meal Types Selection
                        mealTypesSection
                        
                        // Preview Section
                        previewSection
                        
                        // Confirm Button
                        confirmButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Batch Meal Planning")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add All") { 
                    generateBatchMeals()
                    onConfirm() 
                }
                .fontWeight(.semibold)
                .foregroundColor(.lumoGreen)
                .disabled(selectedDates.isEmpty || selectedMealTypes.isEmpty)
            )
        }
        .onAppear {
            generateBatchMeals()
        }
        .onChange(of: selectedDates) { _, _ in generateBatchMeals() }
        .onChange(of: selectedMealTypes) { _, _ in generateBatchMeals() }
        .onChange(of: defaultServings) { _, _ in generateBatchMeals() }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Plan Multiple Meals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select dates and meal types to add \(recipe.name) to your meal plan")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var quickSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Selection")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickBatchButton(title: "This Week", subtitle: "7 days") {
                    selectWeek()
                }
                
                QuickBatchButton(title: "Next 3 Days", subtitle: "Quick plan") {
                    selectNext3Days()
                }
                
                QuickBatchButton(title: "All Dinners", subtitle: "Evening meals") {
                    selectedMealTypes = [.dinner]
                }
                
                QuickBatchButton(title: "All Meals", subtitle: "Full day") {
                    selectedMealTypes = Set(MealType.allCases)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Dates")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Custom date picker with multiple selection would go here
            // For now, using a simplified approach
            VStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) {
                        DateSelectionRow(
                            date: date,
                            isSelected: selectedDates.contains(date)
                        ) {
                            toggleDateSelection(date)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Types")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealTypeSelectionCard(
                        mealType: mealType,
                        isSelected: selectedMealTypes.contains(mealType)
                    ) {
                        toggleMealTypeSelection(mealType)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview (\(batchMeals.count) meals)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if batchMeals.isEmpty {
                Text("Select dates and meal types to see preview")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(batchMeals.prefix(5), id: \.id) { meal in
                        BatchMealPreviewRow(meal: meal)
                    }
                    
                    if batchMeals.count > 5 {
                        Text("+ \(batchMeals.count - 5) more meals")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var confirmButton: some View {
        Button(action: {
            generateBatchMeals()
            onConfirm()
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                
                Text("Add \(batchMeals.count) Meals")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                batchMeals.isEmpty ? 
                AnyView(Color.gray.opacity(0.3)) :
                AnyView(LinearGradient(
                    colors: [.lumoGreen, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            )
            .cornerRadius(12)
        }
        .disabled(batchMeals.isEmpty)
    }
    
    // MARK: - Helper Functions
    
    private func selectWeek() {
        selectedDates = Set((0..<7).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())
        })
    }
    
    private func selectNext3Days() {
        selectedDates = Set((0..<3).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())
        })
    }
    
    private func toggleDateSelection(_ date: Date) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            selectedDates.insert(date)
        }
    }
    
    private func toggleMealTypeSelection(_ mealType: MealType) {
        if selectedMealTypes.contains(mealType) {
            selectedMealTypes.remove(mealType)
        } else {
            selectedMealTypes.insert(mealType)
        }
    }
    
    private func generateBatchMeals() {
        batchMeals = []
        
        for date in selectedDates.sorted() {
            for mealType in selectedMealTypes {
                let batchMeal = BatchMealSelection(
                    date: date,
                    mealType: mealType,
                    servings: defaultServings
                )
                batchMeals.append(batchMeal)
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct BatchMealSelection: Identifiable {
    let id = UUID()
    let date: Date
    let mealType: MealType
    let servings: Int
}

// MARK: - Supporting UI Components

struct InfoChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
    }
}

struct MealTypeSelectionCard: View {
    let mealType: MealType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(mealType.emoji)
                    .font(.title2)
                
                Text(mealType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ? 
                mealType.color.opacity(0.8) : 
                Color.gray.opacity(0.1)
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? mealType.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

struct QuickBatchButton: View {
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct DateSelectionRow: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .lumoGreen : .gray)
            }
            .padding()
            .background(
                isSelected ? 
                Color.lumoGreen.opacity(0.1) : 
                Color.gray.opacity(0.05)
            )
            .cornerRadius(8)
        }
    }
}

struct BatchMealPreviewRow: View {
    let meal: BatchMealSelection
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(meal.mealType.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.mealType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(dateFormatter.string(from: meal.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(meal.servings) servings")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
} 

// MARK: - Additional Sheet Views

struct RecipeIngredientsSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ForEach(recipe.ingredients, id: \.name) { ingredient in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ingredient.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text(ingredient.displayAmount)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.lumoGreen)
                                    .font(.title3)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct RecipeNutritionSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        let nutrition = recipe.nutritionInfo
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Facts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            NutritionRow(label: "Calories", value: "\(nutrition.calories ?? 0)")
                            NutritionRow(label: "Protein", value: String(format: "%.1f", nutrition.protein ?? 0.0) + "g")
                            NutritionRow(label: "Carbs", value: String(format: "%.1f", nutrition.carbs ?? 0.0) + "g")
                            NutritionRow(label: "Fat", value: String(format: "%.1f", nutrition.fat ?? 0.0) + "g")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.lumoGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 