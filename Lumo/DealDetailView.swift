//
//  DealDetailView.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

struct DealDetailView: View {
    let deal: Deal
    @Environment(\.dismiss) private var dismiss
    @State private var showingTerms = false
    @State private var isFavorite = false
    @State private var addedToGroceryList = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Deal Header
                        dealHeaderSection
                        
                        // Deal Description
                        dealDescriptionSection
                        
                        // Products Included
                        productsSection
                        
                        // Terms & Conditions
                        termsSection
                        
                        // Store Information
                        storeSection
                        
                        // Similar Deals
                        similarDealsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Deal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isFavorite.toggle() }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                    }
                }
            }
        }
    }
    
    // MARK: - Deal Header Section
    private var dealHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Deal Badge
            HStack {
                dealTypeBadge
                Spacer()
                expirationBadge
            }
            
            // Deal Title
            Text(deal.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Deal Value
            HStack {
                Text("Save \(deal.discountValue, specifier: "%.0f")%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.lumoGreen)
                
                Spacer()
                
                Text("Valid until \(deal.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Deal Type Badge
    private var dealTypeBadge: some View {
        Text(deal.dealType.displayName)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(deal.dealType.color)
            .cornerRadius(8)
    }
    
    // MARK: - Expiration Badge
    private var expirationBadge: some View {
        let timeRemaining = deal.endDate.timeIntervalSinceNow
        let isExpiringSoon = timeRemaining < 86400 * 2 // Less than 48 hours
        
        return Text(isExpiringSoon ? "ENDING SOON" : "ACTIVE")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isExpiringSoon ? Color.red : Color.lumoGreen)
            .cornerRadius(6)
    }
    
    // MARK: - Deal Description Section
    private var dealDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About This Deal")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(deal.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            // Key Benefits
            VStack(alignment: .leading, spacing: 8) {
                ForEach(deal.benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.lumoGreen)
                            .font(.caption)
                        
                        Text(benefit)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Products Included")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(deal.appliesToProducts.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(deal.appliesToProducts, id: \.self) { productId in
                    if let product = DealsData.getProductById(productId) {
                        DealProductCard(product: product)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Terms & Conditions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingTerms = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(deal.terms.prefix(3), id: \.self) { term in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(term)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Store Section
    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available At")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(deal.applicableStores, id: \.id) { store in
                StoreInfoCard(store: store)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Similar Deals Section
    private var similarDealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar Deals")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DealsData.getActiveDeals().filter { $0.id != deal.id }.prefix(5), id: \.id) { similarDeal in
                        SimilarDealCard(deal: similarDeal)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Deal Product Card
struct DealProductCard: View {
    let product: Product
    @State private var addedToGroceryList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                Button(action: { addedToGroceryList.toggle() }) {
                    Image(systemName: addedToGroceryList ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(addedToGroceryList ? .lumoGreen : .white)
                        .font(.caption)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    if let discountPrice = product.discountPrice {
                        Text("$\(discountPrice, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.lumoGreen)
                        
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .strikethrough()
                    } else {
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Store Info Card
struct StoreInfoCard: View {
    let store: Store
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(store.name.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(store.address), \(store.city), \(store.state) \(store.zip)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("Open until 10 PM")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button("Directions") {
                // Open directions
            }
            .font(.caption)
            .foregroundColor(.lumoGreen)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Similar Deal Card
struct SimilarDealCard: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 80)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .foregroundColor(deal.dealType.color)
                            .font(.title3)
                    )
                
                Text("\(Int(deal.discountValue))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(deal.dealType.color)
                    .cornerRadius(4)
                    .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(deal.appliesToProducts.count) items")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 120)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Deal Type Extension
extension Deal.DealType {
    var displayName: String {
        switch self {
        case .bogo: return "BOGO"
        case .percentageOff: return "% OFF"
        case .dollarOff: return "$ OFF"
        case .clearance: return "CLEARANCE"
        case .bundle: return "BUNDLE"
        }
    }
    
    var color: Color {
        switch self {
        case .bogo: return .lumoGreen
        case .percentageOff: return .orange
        case .dollarOff: return .blue
        case .clearance: return .red
        case .bundle: return .purple
        }
    }
}

// MARK: - Preview
struct DealDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DealDetailView(deal: DealsData.getActiveDeals().first!)
    }
} 