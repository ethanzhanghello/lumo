//
//  ExploreSections.swift
//  Lumo
//
//  Created by Ethan on 7/1/25.
//

import SwiftUI

// MARK: - Nearby Stores Section
struct NearbyStoresSection: View {
    @Binding var selectedStore: Store?
    @State private var selectedStoreType: StoreType? = nil
    
    var filteredStores: [Store] {
        if let selectedType = selectedStoreType {
            return sampleLAStores.filter { $0.storeType == selectedType }
        }
        return sampleLAStores
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Nearby Stores")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full store list
                }
                .font(.subheadline)
                .foregroundColor(Color.lumoGreen)
            }
            .padding(.horizontal)
            
            // Store Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All stores filter
                    StoreTypeFilterButton(
                        title: "All",
                        isSelected: selectedStoreType == nil,
                        action: { selectedStoreType = nil }
                    )
                    
                    // Store type filters
                    ForEach(StoreType.allCases, id: \.self) { storeType in
                        StoreTypeFilterButton(
                            title: storeType.rawValue,
                            icon: storeType.icon,
                            isSelected: selectedStoreType == storeType,
                            action: { selectedStoreType = storeType }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Stores List
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredStores) { store in
                        Button(action: { selectedStore = store }) {
                            StoreCard(store: store)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Store Type Filter Button
struct StoreTypeFilterButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.3))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(16)
        }
    }
}

// MARK: - Store Card
struct StoreCard: View {
    let store: Store
    @State private var isFavorite: Bool
    
    init(store: Store) {
        self.store = store
        self._isFavorite = State(initialValue: store.isFavorite)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Store Image Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(store.storeType.color.opacity(0.3))
                    .frame(width: 160, height: 100)
                
                Image(systemName: store.storeType.icon)
                    .font(.title)
                    .foregroundColor(store.storeType.color)
            }
            
            // Store Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(store.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        isFavorite.toggle()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                            .font(.caption)
                    }
                }
                
                Text(store.city)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(store.hours)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", store.rating))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Smart Recommendations Section
struct SmartRecommendationsSection: View {
    @EnvironmentObject var appState: AppState
    @State private var recommendations: [GroceryItem] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Recommended for You")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Refresh") {
                    generateRecommendations()
                }
                .font(.subheadline)
                .foregroundColor(Color.lumoGreen)
            }
            .padding(.horizontal)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.lumoGreen))
                        .scaleEffect(0.8)
                    Text("Finding recommendations...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Recommendations Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(recommendations, id: \.id) { item in
                        RecommendationCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            generateRecommendations()
        }
    }
    
    private func generateRecommendations() {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Generate recommendations based on cart history and time of day
            let hour = Calendar.current.component(.hour, from: Date())
            var recommendedItems: [GroceryItem] = []
            
            // Morning recommendations (6-11 AM)
            if hour >= 6 && hour < 11 {
                recommendedItems = sampleGroceryItems.filter { item in
                    item.name.contains("Coffee") || 
                    item.name.contains("Bread") || 
                    item.name.contains("Milk") ||
                    item.name.contains("Eggs") ||
                    item.name.contains("Cereal")
                }
            }
            // Lunch recommendations (11 AM - 2 PM)
            else if hour >= 11 && hour < 14 {
                recommendedItems = sampleGroceryItems.filter { item in
                    item.name.contains("Sandwich") || 
                    item.name.contains("Salad") || 
                    item.name.contains("Soup") ||
                    item.name.contains("Fruit") ||
                    item.name.contains("Juice")
                }
            }
            // Dinner recommendations (5-9 PM)
            else if hour >= 17 && hour < 21 {
                recommendedItems = sampleGroceryItems.filter { item in
                    item.name.contains("Pasta") || 
                    item.name.contains("Chicken") || 
                    item.name.contains("Beef") ||
                    item.name.contains("Vegetables") ||
                    item.name.contains("Wine")
                }
            }
            // Default recommendations
            else {
                recommendedItems = sampleGroceryItems.filter { item in
                    item.name.contains("Organic") || 
                    item.name.contains("Fresh") || 
                    item.name.contains("Healthy")
                }
            }
            
            // Filter out items already in cart
            let cartItemIds = Set(appState.shoppingCart.cartItems.map { $0.item.id })
            recommendedItems = recommendedItems.filter { !cartItemIds.contains($0.id) }
            
            // Take random 6 items
            recommendations = Array(recommendedItems.shuffled().prefix(6))
            isLoading = false
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "sparkles")
                        .foregroundColor(Color.lumoGreen)
                        .font(.title2)
                )
            
            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.lumoGreen)
                
                Text("Aisle: \(item.aisle)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Add to Cart Button
            Button(action: {
                appState.shoppingCart.addItem(item)
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.caption2)
                    Text("Add")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.lumoGreen)
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lumoGreen.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Categories Section
struct CategoriesSection: View {
    @Binding var selectedCategory: String?
    
    let categories = [
        ("Dairy & Eggs", "drop.fill", Color.blue),
        ("Produce", "leaf.fill", Color.green),
        ("Meat & Seafood", "fish.fill", Color.red),
        ("Bakery", "birthday.cake.fill", Color.orange),
        ("Pantry", "cabinet.fill", Color.brown),
        ("Frozen", "snowflake", Color.cyan),
        ("Beverages", "cup.and.saucer.fill", Color.purple),
        ("Snacks", "heart.fill", Color.pink),
        ("Health & Beauty", "cross.fill", Color.mint),
        ("Household", "house.fill", Color.indigo)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Categories")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full categories list
                }
                .font(.subheadline)
                .foregroundColor(Color.lumoGreen)
            }
            .padding(.horizontal)
            
            // Categories Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(categories, id: \.0) { category in
                    CategoryCard(
                        title: category.0,
                        icon: category.1,
                        color: category.2,
                        isSelected: selectedCategory == category.0
                    ) {
                        selectedCategory = selectedCategory == category.0 ? nil : category.0
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Featured Items Section
struct FeaturedItemsSection: View {
    @EnvironmentObject var appState: AppState
    var selectedCategory: String?

    var featuredItems: [(String, [GroceryItem])]{
        let all: [(String, [GroceryItem])] = [
            ("Popular This Week", sampleGroceryItems.filter { $0.name.contains("Organic") || $0.name.contains("Fresh") }),
            ("Back-to-School Essentials", sampleGroceryItems.filter { $0.aisle == "Office & School" || $0.aisle == "Health/Beauty" }),
            ("Seasonal Favorites", sampleGroceryItems.filter { $0.aisle == "Seasonal" || $0.name.contains("Holiday") })
        ]
        if let cat = selectedCategory {
            return all.map { (title, items) in
                (title, items.filter { $0.aisle == cat })
            }
        } else {
            return all
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Featured Items")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to featured items
                }
                .font(.subheadline)
                .foregroundColor(Color.lumoGreen)
            }
            .padding(.horizontal)
            
            // Featured Collections
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredItems, id: \.0) { collection in
                        if !collection.1.isEmpty {
                            FeaturedCollectionCard(
                                title: collection.0,
                                items: Array(collection.1.prefix(4))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Featured Collection Card
struct FeaturedCollectionCard: View {
    let title: String
    let items: [GroceryItem]
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            VStack(spacing: 8) {
                ForEach(items.prefix(3)) { item in
                    FeaturedItemRow(item: item)
                }
            }
            .padding(.horizontal, 16)
            
            Button("View All \(items.count) Items") {
                // Navigate to collection
            }
            .font(.caption)
            .foregroundColor(Color.lumoGreen)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Featured Item Row
struct FeaturedItemRow: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 8) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(Color.lumoGreen)
            }
            
            Spacer()
            
            Button(action: {
                appState.shoppingCart.addItem(item)
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color.lumoGreen)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Deals Section
struct DealsSection: View {
    @EnvironmentObject var appState: AppState
    var selectedCategory: String?

    var dealsItems: [GroceryItem] {
        let filtered = sampleGroceryItems.filter { _ in Bool.random() }
        if let cat = selectedCategory {
            return filtered.filter { $0.aisle == cat }
        }
        return filtered
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Today's Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to deals
                }
                .font(.subheadline)
                .foregroundColor(Color.lumoGreen)
            }
            .padding(.horizontal)
            
            // Deals Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(dealsItems), id: \.id) { item in
                    DealCard(item: item)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Deal Card
struct DealCard: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState
    
    var originalPrice: Double {
        item.price * 1.3 // Simulate 30% discount
    }
    
    var discountPercentage: Int {
        Int(((originalPrice - item.price) / originalPrice) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Discount Badge
            HStack {
                Text("\(discountPercentage)% OFF")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                )
            
            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.lumoGreen)
                    
                    Text("$\(originalPrice, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .strikethrough()
                    
                    Spacer()
                }
            }
            
            // Add to Cart Button
            Button(action: {
                appState.shoppingCart.addItem(item)
            }) {
                Text("Add to Cart")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.lumoGreen)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Store Detail View
struct StoreDetailView: View {
    let store: Store

    var body: some View {
        VStack(spacing: 24) {
            Text(store.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(store.city)
                .foregroundColor(.white.opacity(0.7))
            Text("Type: \(store.storeType.rawValue)")
                .foregroundColor(.white.opacity(0.7))
            Text("Hours: \(store.hours)")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
} 