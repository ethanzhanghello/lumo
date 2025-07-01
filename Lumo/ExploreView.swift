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
                        NearbyStoresSection()
                        
                        // Categories Section
                        CategoriesSection(selectedCategory: $selectedCategory)
                        
                        // Featured Items Section
                        FeaturedItemsSection()
                        
                        // Deals Section
                        DealsSection()
                        
                        // Smart Recommendations Section
                        SmartRecommendationsSection()
                        
                        Spacer(minLength: 100)
                    }
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