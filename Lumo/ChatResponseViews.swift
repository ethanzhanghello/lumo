//
//  ChatResponseViews.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

// MARK: - Modern Recipe Card
struct ModernRecipeCard: View {
    let recipe: Recipe
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Recipe Header with Image
            HStack(spacing: 16) {
                // Recipe Image
                AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Recipe Stats
                    HStack(spacing: 16) {
                        RecipeStat(icon: "clock", value: "\(recipe.totalTime)m")
                        RecipeStat(icon: "person.2", value: "\(recipe.servings)")
                        RecipeStat(icon: "dollarsign.circle", value: "$\(String(format: "%.2f", recipe.estimatedCost))")
                    }
                    
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(recipe.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        Text("(\(recipe.reviewCount))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // Dietary Tags
            if !recipe.dietaryInfo.dietaryTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.dietaryInfo.dietaryTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Ingredients Preview
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Ingredients")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(recipe.ingredients.count) items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(recipe.ingredients.prefix(6), id: \.id) { ingredient in
                        HStack {
                            Text("• \(ingredient.displayAmount) \(ingredient.name)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("A\(ingredient.aisle)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                if recipe.ingredients.count > 6 {
                    Button(action: {}) {
                        Text("+ \(recipe.ingredients.count - 6) more ingredients")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Action Buttons
            ModernActionButtonsView(buttons: actionButtons) { action in
                onAction(action)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Modern Meal Suggestion Card
struct ModernMealSuggestionCard: View {
    let recipe: Recipe
    let suggestedDate: Date
    let suggestedMealType: MealType
    let onAddToMealPlan: () -> Void
    let onAddToGroceryList: () -> Void
    let onViewRecipe: () -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipe Header
            HStack(spacing: 12) {
                // Recipe Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                        Label("\(recipe.totalTime) min", systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Meal Plan Suggestion
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.lumoGreen)
                    .font(.caption)
                
                Text("Suggested for \(suggestedMealType.rawValue) on \(suggestedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.lumoGreen.opacity(0.1))
            .cornerRadius(8)
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: onAddToMealPlan) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption)
                        
                        Text("Add to Meal Plan")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.lumoGreen)
                    .cornerRadius(8)
                }
                
                HStack(spacing: 8) {
                    Button(action: onAddToGroceryList) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption)
                            
                            Text("Add Ingredients")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button(action: onViewRecipe) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            
                            Text("View Recipe")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Modern Product Card
struct ModernProductCard: View {
    let product: Product
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Simple Product Card
            HStack {
                VStack(alignment: .leading) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(product.brand ?? "Generic")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", product.basePrice))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                Spacer()
            }
            
            // Simple action buttons
            HStack {
                ForEach(actionButtons, id: \.id) { button in
                    Button(button.title) {
                        onAction(button.action)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                         }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Modern Deal Card
struct ModernDealCard: View {
    let deal: Deal
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            dealHeader
            dealDetails
            dealActions
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }

    private var dealHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "tag.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 8) {
                Text(deal.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(deal.applicableStores.first?.name ?? "All Stores")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                HStack(spacing: 8) {
                    Text("\(Int(deal.discountValue))% OFF")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                    if let originalPrice = deal.maximumDiscount, originalPrice > 0 {
                        Text("Max $\(String(format: "%.2f", originalPrice))")
                            .font(.system(size: 12, weight: .medium))
                            .strikethrough()
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            Spacer()
        }
    }

    private var dealDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !deal.description.isEmpty {
                Text(deal.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }
            HStack(spacing: 16) {
                DealInfoBadge(icon: "calendar", text: deal.endDate.formatted(date: .abbreviated, time: .omitted))
                DealInfoBadge(icon: "location", text: deal.applicableStores.first?.name ?? "All Stores")
            }
        }
    }

    private var dealActions: some View {
        ModernActionButtonsView(buttons: actionButtons) { action in
            onAction(action)
        }
    }
}

// MARK: - Modern Action Buttons View
struct ModernActionButtonsView: View {
    let buttons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    @State private var showButtons = false
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                ModernActionButton(button: button) {
                    onAction(button.action)
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: showButtons)
            }
        }
        .onAppear {
            print("ModernActionButtonsView buttons: \(buttons.map { $0.title })")
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showButtons = true
            }
        }
    }
}

// MARK: - Modern Action Button
struct ModernActionButton: View {
    let button: ChatActionButton
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("Button tapped: \(button.title) with action: \(button.action)")
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: button.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(button.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: button.color).opacity(0.8),
                                Color(hex: button.color).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: button.color).opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(false) // Force enabled
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Supporting Views
struct RecipeStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct ProductInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DealInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}



 