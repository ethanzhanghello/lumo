//
//  ExploreView.swift
//  Lumo
//
//  Created by Ethan on 7/1/25.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedStoreType: StoreType? = nil
    @State private var selectedStore: Store? = nil
    @State private var showFavoritesSheet: Bool = false
    @State private var selectedFavoriteStore: Store? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Explore")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { showFavoritesSheet = true }) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                        .padding(8)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Show Favorited Stores")
                            }
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
                            .environmentObject(authViewModel)
                        
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
                // Sheet for favorited stores
                .sheet(isPresented: $showFavoritesSheet) {
                    NavigationView {
                        List {
                            ForEach(sampleLAStores.filter { authViewModel.favoriteStoreIDs.contains($0.id.uuidString) }) { store in
                                Button(action: {
                                    selectedFavoriteStore = store
                                    showFavoritesSheet = false
                                }) {
                                    HStack {
                                        Image(systemName: store.storeType.icon)
                                            .foregroundColor(store.storeType.color)
                                        Text(store.name)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .onAppear {
                            print("Current favoriteStoreIDs in ExploreView: \(authViewModel.favoriteStoreIDs)")
                        }
                        .navigationTitle("Favorited Stores")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showFavoritesSheet = false }
                            }
                        }
                    }
                }
                // NavigationLink for selected favorite store
                NavigationLink(
                    destination: Group {
                        if let store = selectedFavoriteStore {
                            StoreDetailView(store: store)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedFavoriteStore != nil },
                        set: { if !$0 { selectedFavoriteStore = nil } }
                    )
                ) {
                    EmptyView()
                }
            }
        }
        .task {
            await authViewModel.fetchProfile()
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
} 
