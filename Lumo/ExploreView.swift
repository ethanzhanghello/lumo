//
//  ExploreView.swift
//  Lumo
//
//  Created by Ethan on 7/1/25.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedStoreType: StoreType? = nil
    @State private var selectedStore: Store? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Explore")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search stores, categories, or items...", text: $searchText)
                                    .foregroundColor(.white)
                                    .textFieldStyle(.plain)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.lumoGreen.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Nearby Stores Section
                        NearbyStoresSection(selectedStore: $selectedStore)
                        
                        // Categories Section
                        CategoriesSection(selectedCategory: $selectedCategory)
                        
                        // Featured Items Section
                        FeaturedItemsSection(selectedCategory: selectedCategory)
                        
                        // Deals Section
                        DealsSection(selectedCategory: selectedCategory)
                        
                        // Smart Recommendations Section
                        SmartRecommendationsSection()
                        
                        Spacer(minLength: 100)
                    }
                }
                // NavigationLink for Store Detail
                NavigationLink(
                    destination: Group {
                        if let store = selectedStore {
                            StoreDetailView(store: store)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedStore != nil },
                        set: { if !$0 { selectedStore = nil } }
                    )
                ) {
                    EmptyView()
                }
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(AppState())
    }
} 