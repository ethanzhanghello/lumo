//
//  ExploreSections.swift
//  Lumo
//
//  Created by Ethan on 7/1/25. Edited by Ethan on 7/2/25.
//

import SwiftUI

// MARK: - Nearby Stores Section
struct NearbyStoresSection: View {
    @Binding var selectedStore: Store?
    @State private var selectedStoreType: StoreType? = nil
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    
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
                                .environmentObject(authViewModel)
                                .environmentObject(appState)
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
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var heartScale: CGFloat = 1.0
    
    var isFavorite: Bool {
        authViewModel.favoriteStoreIDs.contains(store.id.uuidString)
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
                        guard !isLoading else { return }
                        isLoading = true
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                            heartScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                heartScale = 1.0
                            }
                        }
                        Task {
                            await authViewModel.toggleFavoriteStore(
                                store,
                                fullName: authViewModel.email, // You may want to use the actual full name if available
                                dietaryFilter: false,
                                profilePictureURL: authViewModel.profilePictureURL,
                                allergies: authViewModel.allergies,
                                preferredCuisines: authViewModel.preferredCuisines,
                                dietaryRestrictions: authViewModel.dietaryRestrictions
                            )
                            isLoading = false
                        }
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                            .font(.caption)
                            .scaleEffect(heartScale)
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
            let cartItemIds = Set(appState.groceryList.groceryItems.map { $0.item.id })
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
                appState.groceryList.addItem(item)
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
    @State private var showingCategoryStores = false
    @State private var tappedCategory: String? = nil
    
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
                    Button(action: {
                        tappedCategory = category.0
                        showingCategoryStores = true
                    }) {
                        CategoryCard(
                            title: category.0,
                            icon: category.1,
                            color: category.2,
                            isSelected: selectedCategory == category.0
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingCategoryStores) {
            if let category = tappedCategory {
                CategoryStoresView(category: category)
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
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

// MARK: - Featured Items Section
struct FeaturedItemsSection: View {
    @EnvironmentObject var appState: AppState
    var selectedCategory: String?

    var featuredItems: [(String, [GroceryItem])]{
        let all: [(String, [GroceryItem])] = [
            ("Popular This Week", sampleGroceryItems.filter { $0.name.contains("Organic") || $0.name.contains("Fresh") }),
            ("Back-to-School Essentials", sampleGroceryItems.filter { $0.name.contains("Office & School") || $0.name.contains("Health/Beauty") }),
            ("Seasonal Favorites", sampleGroceryItems.filter { $0.name.contains("Seasonal") || $0.name.contains("Holiday") })
        ]
        if let cat = selectedCategory {
            return all.map { (title, items) in
                (title, items.filter { $0.category == cat })
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
                appState.groceryList.addItem(item)
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
    var selectedCategory: String?
    @State private var showDealsView = false

    var dealsItems: [GroceryItem] {
        let filtered = sampleGroceryItems.filter { _ in Bool.random() }
        if let cat = selectedCategory {
            return filtered.filter { $0.category == cat }
        }
        return filtered
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Deals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button("View All") {
                    showDealsView = true
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
            NavigationLink(destination: DealsView(), isActive: $showDealsView) { EmptyView() }
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
                appState.groceryList.addItem(item)
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
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var filteredItems: [GroceryItem] {
        var items = sampleGroceryItems // All available items at this store
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                                   $0.description.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by selected category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        return items
    }
    
    var categories: [String] {
        Array(Set(sampleGroceryItems.map { $0.category })).sorted()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Store Header
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(store.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "heart")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Store Info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.city)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Type: \(store.storeType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", store.rating))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                Text(store.hours)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search items...", text: $searchText)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All categories filter
                            CategoryFilterButton(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            // Category filters
                            ForEach(categories, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Items List
                    if filteredItems.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "bag")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text(searchText.isEmpty ? "No items found" : "No items match your search")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            if !searchText.isEmpty {
                                Text("Try different keywords")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredItems) { item in
                                    ItemCard(item: item)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Store Item Card
struct StoreItemCard: View {
    let item: GroceryItem
    let store: Store
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 100)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                )
            
            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                Text("Aisle: \(item.aisle)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack {
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.lumoGreen)
                    
                    Spacer()
                    
                    Button(action: {
                        appState.groceryList.addItem(item)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.lumoGreen)
                            .font(.title3)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Stores View
struct CategoryStoresView: View {
    let category: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var storesWithCategoryItems: [Store] {
        // Filter stores that have items from this category
        return sampleLAStores.filter { store in
            // For demo purposes, assume all stores have items from all categories
            // In a real app, you'd check the store's actual inventory
            return true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(category)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("Stores with \(category) items")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search stores...", text: $searchText)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Stores List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(storesWithCategoryItems) { store in
                                CategoryStoreCard(store: store, category: category)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Category Store Card
struct CategoryStoreCard: View {
    let store: Store
    let category: String
    @State private var showingStoreDetail = false
    
    var categoryItems: [GroceryItem] {
        // Get items from this category
        return sampleGroceryItems.filter { $0.category == category }.prefix(3).map { $0 }
    }
    
    var body: some View {
        Button(action: {
            showingStoreDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Store Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(store.city)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", store.rating))
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(store.storeType.rawValue)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(categoryItems.count)+ items")
                            .font(.caption)
                            .foregroundColor(Color.lumoGreen)
                        
                        Text("in \(category)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Sample Items
                HStack(spacing: 8) {
                    ForEach(categoryItems, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.caption2)
                                .foregroundColor(Color.lumoGreen)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                
                // View Store Button
                HStack {
                    Text("View Store")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.lumoGreen)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.lumoGreen)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingStoreDetail) {
            StoreDetailView(store: store)
        }
    }
}

struct ItemCard: View {
    @EnvironmentObject var appState: AppState
    let item: GroceryItem
    @State private var showingItemDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                )
                .onTapGesture {
                    showingItemDetail = true
                }
            
            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .onTapGesture {
                        showingItemDetail = true
                    }
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                Text("Aisle: \(item.aisle)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack {
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.lumoGreen)
                    
                    Spacer()
                }
            }
            .onTapGesture {
                showingItemDetail = true
            }
            
            // Add to Cart Button
            Button(action: {
                appState.groceryList.addItem(item)
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
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

 
