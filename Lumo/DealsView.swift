//
//  DealsView.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

struct DealsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: DealFilter = .all
    @State private var selectedSort: DealSort = .relevance
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingCouponDetail = false
    @State private var selectedDeal: Deal?
    @State private var showingDealDetail = false
    @State private var selectedStore: String?
    
    // Mock user profile for personalization
    private let userProfile = UserProfile.sampleProfile
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with Search and Filters
                        headerSection
                        
                        // Top Picks for You
                        topPicksSection
                        
                        // Featured Weekly Deals
                        featuredDealsSection
                        
                        // BOGO & Bundle Offers
                        bogoOffersSection
                        
                        // Store-Wide Discounts
                        storeDiscountsSection
                        
                        // Last Chance / Ending Soon
                        lastChanceSection
                        
                        // Digital Coupons
                        digitalCouponsSection
                        
                        // Explore by Category
                        exploreByCategorySection
                        
                        // In-Store Only Deals
                        inStoreDealsSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Deals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            DealFiltersView(
                selectedFilter: $selectedFilter,
                selectedSort: $selectedSort,
                selectedStore: $selectedStore,
                selectedCategory: $selectedCategory
            )
        }
        .sheet(isPresented: $showingDealDetail) {
            if let deal = selectedDeal {
                DealDetailView(deal: deal)
            }
        }
        .sheet(isPresented: $showingCouponDetail) {
            CouponDetailView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search deals...", text: $searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Active Filters
            if selectedFilter != .all || selectedSort != .relevance {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if selectedFilter != .all {
                            FilterChip(text: selectedFilter.displayName, isActive: true) {
                                selectedFilter = .all
                            }
                        }
                        
                        if selectedSort != .relevance {
                            FilterChip(text: selectedSort.displayName, isActive: true) {
                                selectedSort = .relevance
                            }
                        }
                        
                        if let store = selectedStore {
                            FilterChip(text: sampleLAStores.first(where: { $0.zip == store })?.name ?? "Store", isActive: true) {
                                selectedStore = nil
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Top Picks Section
    private var topPicksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Picks for You")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to personalized deals
                }
                .foregroundColor(.lumoGreen)
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DealsData.getRecommendedProducts(for: userProfile), id: \.id) { product in
                        PersonalizedDealCard(product: product, userProfile: userProfile)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Featured Deals Section
    private var featuredDealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Weekly Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Ends Sunday")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DealsData.getActiveDeals().prefix(5), id: \.id) { deal in
                        FeaturedDealCard(deal: deal)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - BOGO Offers Section
    private var bogoOffersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BOGO & Bundle Offers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to BOGO deals
                }
                .foregroundColor(.lumoGreen)
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DealsData.getActiveDeals().filter { $0.dealType == .bogo }, id: \.id) { deal in
                    BOGODealCard(deal: deal)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Store Discounts Section
    private var storeDiscountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Store-Wide Discounts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Filter by Store") {
                    // Show store filter
                }
                .foregroundColor(.lumoGreen)
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            ForEach(DealsData.getActiveDeals().filter { $0.dealType == .percentageOff }, id: \.id) { deal in
                StoreDiscountCard(deal: deal)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Last Chance Section
    private var lastChanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Chance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Ending Soon")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DealsData.getActiveDeals().filter { deal in
                        let timeRemaining = deal.endDate.timeIntervalSinceNow
                        return timeRemaining < 86400 * 2 // Less than 48 hours
                    }, id: \.id) { deal in
                        LastChanceDealCard(deal: deal)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Digital Coupons Section
    private var digitalCouponsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Digital Coupons")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Clip All") {
                    // Clip all available coupons
                }
                .foregroundColor(.lumoGreen)
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DealsData.getDigitalCoupons(), id: \.id) { coupon in
                    DigitalCouponCard(coupon: coupon)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Explore by Category Section
    private var exploreByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore by Category")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Category.categories.prefix(6), id: \.id) { category in
                    CategoryDealCard(category: category)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - In-Store Deals Section
    private var inStoreDealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("In-Store Only Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "location.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            .padding(.horizontal)
            
            ForEach(DealsData.getProductsWithDeals().prefix(3), id: \.id) { product in
                InStoreDealCard(product: product)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Deal Filter & Sort Enums
enum DealFilter: String, CaseIterable {
    case all = "all"
    case bogo = "bogo"
    case percentageOff = "percentage"
    case dollarOff = "dollar"
    case clearance = "clearance"
    case expiringSoon = "expiring"
    
    var displayName: String {
        switch self {
        case .all: return "All Deals"
        case .bogo: return "BOGO"
        case .percentageOff: return "% Off"
        case .dollarOff: return "$ Off"
        case .clearance: return "Clearance"
        case .expiringSoon: return "Ending Soon"
        }
    }
}

enum DealSort: String, CaseIterable {
    case relevance = "relevance"
    case percentOff = "percent"
    case newest = "newest"
    case priceLow = "price_low"
    case priceHigh = "price_high"
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .percentOff: return "% Off"
        case .newest: return "Newest"
        case .priceLow: return "Price: Low to High"
        case .priceHigh: return "Price: High to Low"
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let text: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.caption)
                    .foregroundColor(isActive ? .black : .white)
                
                if isActive {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.lumoGreen : Color.gray.opacity(0.3))
            .cornerRadius(16)
        }
    }
}

// MARK: - Deal Card Components
struct PersonalizedDealCard: View {
    let product: Product
    let userProfile: UserProfile
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 100)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(8)
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
                
                if userProfile.favorites.contains(product.id) {
                    Text("Your Favorite")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .frame(width: 140)
    }
}

struct FeaturedDealCard: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 120)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                    )
                
                Text("FEATURED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(deal.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(deal.discountValue))% OFF")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.lumoGreen)
                    
                    Spacer()
                    
                    Text("\(deal.appliesToProducts.count) items")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 200)
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BOGODealCard: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .overlay(
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.lumoGreen)
                            Text("BOGO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.lumoGreen)
                        }
                    )
                
                Text("FREE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.lumoGreen)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(deal.appliesToProducts.count) items included")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button("View Items") {
                    // Show deal details
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StoreDiscountCard: View {
    let deal: Deal
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "percent")
                        .foregroundColor(.orange)
                        .font(.title2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(deal.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(deal.discountValue))% OFF")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text("Store-wide")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LastChanceDealCard: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 160, height: 100)
                    .overlay(
                        Image(systemName: "clock.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    )
                
                Text("ENDING")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("Expires in \(timeRemaining)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var timeRemaining: String {
        let timeInterval = deal.endDate.timeIntervalSinceNow
        if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))m"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))h"
        } else {
            return "\(Int(timeInterval / 86400))d"
        }
    }
}

struct DigitalCouponCard: View {
    let coupon: DigitalCoupon
    @State private var isClipped = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "ticket.fill")
                            .foregroundColor(.lumoGreen)
                            .font(.title2)
                    )
                
                Button(action: { isClipped.toggle() }) {
                    Image(systemName: isClipped ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(isClipped ? .lumoGreen : .white)
                        .font(.title3)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.lumoGreen)
                
                Text(coupon.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text(isClipped ? "Clipped" : "Clip Coupon")
                    .font(.caption2)
                    .foregroundColor(isClipped ? .lumoGreen : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isClipped ? Color.lumoGreen.opacity(0.2) : Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryDealCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 60)
                .overlay(
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.color))
                        .font(.title2)
                )
            
            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InStoreDealCard: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
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
                
                HStack {
                    Text("Aisle \(product.aisle)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button("Add to Route") {
                        // Add to navigation route
                    }
                    .font(.caption2)
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct DealsView_Previews: PreviewProvider {
    static var previews: some View {
        DealsView()
            .environmentObject(AppState())
    }
} 