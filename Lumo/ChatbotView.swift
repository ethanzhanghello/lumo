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
    @State private var isInputExpanded = false
    @FocusState private var isInputFocused: Bool

    @State private var showWelcomeAnimation = false
    @State private var showConfirmation: Bool = false
    @State private var confirmationMessage: String = ""
    
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
                            .padding(.bottom, 100)
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
                }
                
                // Modern Input Bar
                VStack {
                    Spacer()
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
        }
        .onAppear {
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
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch action {
        case .addToList, .addToCart:
            // Add all recipe or product ingredients to grocery list
            if let recipe = message.recipe {
                for ingredient in recipe.ingredients {
                    let groceryItem = GroceryItem(
                        name: ingredient.name,
                        description: ingredient.notes ?? "",
                        price: ingredient.estimatedPrice,
                        category: "Produce",
                        aisle: ingredient.aisle,
                        brand: ""
                    )
                    appState.groceryList.addItem(groceryItem)
                }
                showConfirmationToast("Added all ingredients to your grocery list!")
            } else if let product = message.product {
                let groceryItem = GroceryItem(
                    name: product.name,
                    description: product.description,
                    price: product.price,
                    category: product.category,
                    aisle: product.aisle,
                    brand: product.brand
                )
                appState.groceryList.addItem(groceryItem)
                showConfirmationToast("Added \(product.name) to your grocery list!")
            }
        case .mealPlan:
            // Add recipe to today's meal plan as dinner
            if let recipe = message.recipe {
                let today = Calendar.current.startOfDay(for: Date())
                let meal = MealPlan.Meal(
                    type: .dinner,
                    recipe: recipe,
                    customMeal: nil,
                    ingredients: recipe.ingredients.map { ing in
                        GroceryItem(
                            name: ing.name,
                            description: ing.notes ?? "",
                            price: ing.estimatedPrice,
                            category: "Produce",
                            aisle: ing.aisle,
                            brand: ""
                        )
                    }
                )
                if let idx = appState.mealPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                    appState.mealPlans[idx].meals.append(meal)
                } else {
                    appState.mealPlans.append(MealPlan(date: today, meals: [meal], notes: nil))
                }
                showConfirmationToast("Added \(recipe.name) to your meal plan for today!")
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
            showMealIngredients(message)
        case .surpriseMeal:
            generateSurpriseMeal()
        case .showRecipe:
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