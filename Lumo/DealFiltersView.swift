//
//  DealFiltersView.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

struct DealFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: DealFilter
    @Binding var selectedSort: DealSort
    @Binding var selectedStore: String?
    @Binding var selectedCategory: String?
    
    @State private var selectedDietaryPreferences: Set<String> = []
    @State private var selectedExpirationFilter: String = "all"
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 100
    @State private var priceRange: ClosedRange<Double> = 0...100
    @State private var showInStoreOnly = false
    @State private var showDigitalCouponsOnly = false
    
    private let dietaryPreferences = [
        "Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", 
        "Nut-Free", "Organic", "Non-GMO", "Keto", "Paleo"
    ]
    
    private let expirationFilters = [
        "all": "All Deals",
        "today": "Expires Today",
        "week": "This Week Only",
        "month": "This Month"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    mainContent
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(.lumoGreen)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            dealTypeFilterSection
            sortSection
            storeFilterSection
            categoryFilterSection
            dietaryPreferencesSection
            expirationFilterSection
            priceRangeSection
            additionalFiltersSection
            applyButton
        }
        .padding()
    }
    
    // MARK: - Deal Type Filter Section
    private var dealTypeFilterSection: some View {
        filterSection(
            title: "Deal Type",
            items: DealFilter.allCases.map { $0.displayName },
            selectedItems: [selectedFilter.displayName]
        ) { item in
            if let filter = DealFilter.allCases.first(where: { $0.displayName == item }) {
                selectedFilter = filter
            }
        }
    }
    
    // MARK: - Filter Section
    private func filterSection(
        title: String,
        items: [String],
        selectedItems: [String],
        onSelection: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    FilterOptionButton(
                        title: item,
                        isSelected: selectedItems.contains(item),
                        onTap: { onSelection(item) }
                    )
                }
            }
        }
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sort By")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(DealSort.allCases, id: \.self) { sort in
                    SortOptionButton(
                        title: sort.displayName,
                        isSelected: selectedSort == sort,
                        onTap: { selectedSort = sort }
                    )
                }
            }
        }
    }
    
    // MARK: - Store Filter Section
    private var storeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Store")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            storeFilterList
        }
    }

    private var storeFilterList: some View {
        VStack(spacing: 8) {
            ForEach(sampleLAStores, id: \.zip) { store in
                storeFilterListItem(for: store)
            }
        }
    }

    private func storeFilterListItem(for store: Store) -> some View {
        StoreFilterButton(
            store: store,
            isSelected: selectedStore == store.zip,
            onTap: {
                if selectedStore == store.zip {
                    selectedStore = nil
                } else {
                    selectedStore = store.zip
                }
            }
        )
    }
    
    // MARK: - Category Filter Section
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            categoryGrid
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Category.categories, id: \.id) { category in
                categoryGridItem(for: category)
            }
        }
    }

    private func categoryGridItem(for category: Category) -> some View {
        CategoryIconFilterButton(
            category: category,
            isSelected: selectedCategory == category.id,
            onTap: {
                if selectedCategory == category.id {
                    selectedCategory = nil
                } else {
                    selectedCategory = category.id
                }
            }
        )
    }
    
    // MARK: - Dietary Preferences Section
    private var dietaryPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Preferences")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            dietaryPreferencesGrid
        }
    }

    private var dietaryPreferencesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(dietaryPreferences, id: \.self) { preference in
                dietaryPreferenceGridItem(for: preference)
            }
        }
    }

    private func dietaryPreferenceGridItem(for preference: String) -> some View {
        FilterOptionButton(
            title: preference,
            isSelected: selectedDietaryPreferences.contains(preference),
            onTap: {
                if selectedDietaryPreferences.contains(preference) {
                    selectedDietaryPreferences.remove(preference)
                } else {
                    selectedDietaryPreferences.insert(preference)
                }
            }
        )
    }

    // MARK: - Expiration Filter Section
    private var expirationFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiration")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            expirationFilterList
        }
    }

    private var expirationFilterList: some View {
        VStack(spacing: 8) {
            ForEach(expirationFilters.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                expirationFilterListItem(forKey: key, value: value)
            }
        }
    }

    private func expirationFilterListItem(forKey key: String, value: String) -> some View {
        SortOptionButton(
            title: value,
            isSelected: selectedExpirationFilter == key,
            onTap: { selectedExpirationFilter = key }
        )
    }
    
    // MARK: - Price Range Section
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Range")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            HStack {
                Text("$\(Int(minPrice))")
                    .foregroundColor(.white)
                Spacer()
                Text("$\(Int(maxPrice))")
                    .foregroundColor(.white)
            }
            Slider(value: $minPrice, in: 0...maxPrice, step: 1) {
                Text("Min Price")
            } onEditingChanged: { _ in
                priceRange = minPrice...maxPrice
            }
            .accentColor(.lumoGreen)
            Slider(value: $maxPrice, in: minPrice...100, step: 1) {
                Text("Max Price")
            } onEditingChanged: { _ in
                priceRange = minPrice...maxPrice
            }
            .accentColor(.lumoGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Additional Filters Section
    private var additionalFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Filters")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Toggle("In-Store Only", isOn: $showInStoreOnly)
                    .foregroundColor(.white)
                    .toggleStyle(SwitchToggleStyle(tint: .lumoGreen))
                
                Toggle("Digital Coupons Only", isOn: $showDigitalCouponsOnly)
                    .foregroundColor(.white)
                    .toggleStyle(SwitchToggleStyle(tint: .lumoGreen))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Apply Filters")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lumoGreen)
                .cornerRadius(12)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Reset Filters
    private func resetFilters() {
        selectedFilter = .all
        selectedSort = .relevance
        selectedStore = nil
        selectedCategory = nil
        selectedDietaryPreferences.removeAll()
        selectedExpirationFilter = "all"
        minPrice = 0
        maxPrice = 100
        priceRange = 0...100
        showInStoreOnly = false
        showDigitalCouponsOnly = false
    }
}

// MARK: - Filter Components
struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}

struct SortOptionButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.lumoGreen)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.lumoGreen.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct StoreFilterButton: View {
    let store: Store
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
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
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.lumoGreen.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct CategoryIconFilterButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 32)
                    .overlay(
                        Image(systemName: category.icon)
                            .foregroundColor(Color(hex: category.color))
                            .font(.caption)
                    )
                
                Text(category.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(4)
            .background(isSelected ? Color.lumoGreen.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview
struct DealFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        DealFiltersView(
            selectedFilter: .constant(.all),
            selectedSort: .constant(.relevance),
            selectedStore: .constant(nil),
            selectedCategory: .constant(nil)
        )
    }
} 