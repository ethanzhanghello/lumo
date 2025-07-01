//
//  ExploreSections.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import SwiftUI

// MARK: - Nearby Stores Section
struct NearbyStoresSection: View {
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
                        StoreCard(store: store)
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