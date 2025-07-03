//
//  ChatResponseViews.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

// MARK: - Recipe Response View
struct RecipeResponseView: View {
    let recipe: Recipe
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recipe Header
            HStack {
                AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Label("\(recipe.totalTime) min", systemImage: "clock")
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                        Label("$\(String(format: "%.2f", recipe.estimatedCost))", systemImage: "dollarsign.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(recipe.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    Text("(\(recipe.reviewCount))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Dietary Tags
            if !recipe.dietaryInfo.dietaryTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.dietaryInfo.dietaryTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Ingredients Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(recipe.ingredients.prefix(6), id: \.id) { ingredient in
                        HStack {
                            Text("• \(ingredient.displayAmount) \(ingredient.name)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Aisle \(ingredient.aisle)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if recipe.ingredients.count > 6 {
                    Text("+ \(recipe.ingredients.count - 6) more ingredients")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Action Buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(actionButtons) { button in
                    Button(action: {
                        onAction(button.action)
                    }) {
                        HStack {
                            Image(systemName: button.icon)
                                .font(.caption)
                            Text(button.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: button.color))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Product Response View
struct ProductResponseView: View {
    let product: Product
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Product Header
            HStack {
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "cube.box")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(product.brand)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        if let discountPrice = product.discountPrice {
                            Text("$\(String(format: "%.2f", discountPrice))")
                                .font(.caption)
                                .strikethrough()
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Aisle \(product.aisle)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text(product.shelfPosition)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Stock Status
            HStack {
                Label("Stock: \(product.stockQty)", systemImage: "cube.box")
                    .font(.caption)
                    .foregroundColor(product.stockQty > product.lowStockThreshold ? .green : .orange)
                
                Spacer()
                
                if product.stockQty <= product.lowStockThreshold {
                    Label("Low Stock", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Deal Info
            if let dealType = product.dealType {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.yellow)
                    Text(dealType.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    if let discountPrice = product.discountPrice {
                        Text("Save $\(String(format: "%.2f", product.price - discountPrice))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Action Buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(actionButtons) { button in
                    Button(action: {
                        onAction(button.action)
                    }) {
                        HStack {
                            Image(systemName: button.icon)
                                .font(.caption)
                            Text(button.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: button.color))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Deal Response View
struct DealResponseView: View {
    let deal: Deal
    let actionButtons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Deal Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deal.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(deal.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(deal.discountValue)\(deal.dealType == .percentageOff ? "%" : "$")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("OFF")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Deal Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Valid until \(formatDate(deal.endDate))", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Label("\(deal.applicableStores.count) stores", systemImage: "building.2")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if !deal.benefits.isEmpty {
                    Text("Benefits:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ForEach(deal.benefits.prefix(3), id: \.self) { benefit in
                        Text("• \(benefit)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Action Buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(actionButtons) { button in
                    Button(action: {
                        onAction(button.action)
                    }) {
                        HStack {
                            Image(systemName: button.icon)
                                .font(.caption)
                            Text(button.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: button.color))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Action Buttons View
struct ChatActionButtonsView: View {
    let buttons: [ChatActionButton]
    let onAction: (ChatAction) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(buttons) { button in
                Button(action: {
                    onAction(button.action)
                }) {
                    HStack {
                        Image(systemName: button.icon)
                            .font(.caption)
                        Text(button.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: button.color))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

 