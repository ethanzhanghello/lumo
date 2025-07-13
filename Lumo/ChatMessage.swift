//
//  ChatMessage.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let recipe: Recipe?
    let product: Product?
    let deal: Deal?
    let actionButtons: [ChatActionButton]
    
    init(content: String, isUser: Bool, recipe: Recipe? = nil, product: Product? = nil, deal: Deal? = nil, actionButtons: [ChatActionButton] = []) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.recipe = recipe
        self.product = product
        self.deal = deal
        self.actionButtons = actionButtons
    }
}

struct ChatActionButton: Identifiable, Codable {
    let id = UUID()
    let title: String
    let action: ChatAction
    let icon: String
    let color: String // Hex color string
    
    init(title: String, action: ChatAction, icon: String, color: String = "#00FF88") {
        self.title = title
        self.action = action
        self.icon = icon
        self.color = color
    }
}

enum ChatAction: String, Codable, CaseIterable {
    case addToList = "add_to_list"
    case showAisle = "show_aisle"
    case showRecipe = "show_recipe"
    case scaleRecipe = "scale_recipe"
    case findAlternatives = "find_alternatives"
    case clipCoupon = "clip_coupon"
    case showDeals = "show_deals"
    case navigateTo = "navigate_to"
    case addToFavorites = "add_to_favorites"
    case shareRecipe = "share_recipe"
    case filterByDiet = "filter_by_diet"
    case showNutrition = "show_nutrition"
    case findInStore = "find_in_store"
    case comparePrices = "compare_prices"
    case mealPlan = "meal_plan"
    case pantryCheck = "pantry_check"
    case budgetFilter = "budget_filter"
    case timeFilter = "time_filter"
    case allergenCheck = "allergen_check"
    case storeInfo = "store_info"
    case addToCart = "add_to_cart"
    case showIngredients = "show_ingredients"
    case surpriseMeal = "surprise_meal"
} 