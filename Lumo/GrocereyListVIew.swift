// GroceryListView.swift
// Lumo
//
// Created by Tony on 6/18/25.
//

import SwiftUI
import Combine // Required for ObservableObject and @Published
import Foundation

struct GroceryListView: View {
    @EnvironmentObject var appState: AppState // Access shared state
    @State private var searchText: String = "" // For adding items via search
    @State private var showingShareSheet: Bool = false // For the invite button

    // MARK: - Gemini Recommendation States
    @State private var recommendedItems: [GroceryItem] = []
    @State private var isLoadingRecommendations: Bool = false
    @State private var recommendationError: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header: My Grocery List & Estimated Stats
            VStack(spacing: 5) {
                Text("My Grocery List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)

                Text("Estimated total shopping time: \(appState.shoppingCart.estimatedTimeMinutes) Minutes")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text("Estimated total: $\(appState.shoppingCart.totalCost, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 20)

            // MARK: - Search Bar for Adding Items
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Add an item...", text: $searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .onSubmit {
                        if !searchText.isEmpty {
                            addItemToCartFromSearch()
                        }
                    }
            }
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.lumoGreen.opacity(0.5), lineWidth: 1)
            )
            .padding([.horizontal, .bottom])

            // MARK: - "Your List" Section Header & Invite Button
            HStack {
                Text("Your List")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Invite to Grocery List")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.lumoGreen)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            // MARK: - List of Grocery Items in Cart
            ScrollView {
                VStack(spacing: 10) {
                    if appState.shoppingCart.isEmpty {
                        Text("Your shopping cart is empty. Add some items!")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    } else {
                        ForEach(appState.shoppingCart.cartItems) { cartItem in
                            GroceryListItemRow(cartItem: cartItem)
                                .padding(.horizontal)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteItem(cartItem.item)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.vertical, 10)

            // MARK: - You Might Also Like Section
            VStack(alignment: .leading, spacing: 15) {
                Text("You Might Also Like")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 20)

                if isLoadingRecommendations {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.lumoGreen))
                        .scaleEffect(1.5)
                        .padding()
                } else if let error = recommendationError {
                    Text("Error loading recommendations: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if recommendedItems.isEmpty {
                    Text("No recommendations available at the moment.")
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(recommendedItems) { item in
                            RecommendedItemCard(item: item)
                                .environmentObject(appState) // Pass appState to the card
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)

            Spacer() // Pushes content to the top, allowing the "Start Route" button to sit at the bottom

            // MARK: - Start Route Button
            Button(action: {
                print("Start Route tapped from Grocery List!")
                // Implement navigation or action to start route
            }) {
                HStack {
                    Image(systemName: "chevron.backward.2")
                    Text("Start Route")
                    Image(systemName: "chevron.forward.2")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color.lumoGreen, Color.cyan]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
                .shadow(color: Color.lumoGreen.opacity(0.6), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 20) // Add bottom padding for the button
        }
        .sheet(isPresented: $showingShareSheet) {
            // UIActivityViewController for sharing
            ShareSheet(activityItems: ["Check out my grocery list on Lumo!", URL(string: "https://www.lumoapp.com")!])
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            fetchRandomRecommendedItems() // Call the new random fetch
        }
        // No need to observe shoppingCart.items for random recommendations
    }

    // MARK: - Helper to add item from search
    private func addItemToCartFromSearch() {
        if let foundItem = sampleGroceryItems.first(where: { $0.name.lowercased() == searchText.lowercased() }) {
            appState.shoppingCart.addItem(foundItem)
            print("Added '\(foundItem.name)' from search to cart.")
            searchText = "" // Clear search bar after adding
        } else {
            print("Item '\(searchText)' not found in sample data.")
            // Optionally, show an alert to the user
        }
    }

    // MARK: - Helper to delete item from cart
    private func deleteItem(_ itemToDelete: GroceryItem) {
        appState.shoppingCart.removeItem(itemToDelete)
        print("Removed '\(itemToDelete.name)' from cart.")
    }

    // MARK: - New function to fetch random recommended items
    private func fetchRandomRecommendedItems() {
        isLoadingRecommendations = true
        recommendationError = nil
        recommendedItems = [] // Clear previous recommendations

        let numberOfRecommendations = Int.random(in: 2...4)
        var uniqueRecommendations: Set<GroceryItem> = [] // Use a Set to ensure uniqueness

        // Filter out items already in the cart from potential recommendations
        let availableItems = sampleGroceryItems.filter { item in
            !appState.shoppingCart.cartItems.contains(where: { $0.item.id == item.id })
        }

        while uniqueRecommendations.count < numberOfRecommendations && uniqueRecommendations.count < availableItems.count {
            if let randomItem = availableItems.randomElement() {
                uniqueRecommendations.insert(randomItem)
            }
        }
        
        // Convert the Set back to an Array for display
        recommendedItems = Array(uniqueRecommendations)
        
        isLoadingRecommendations = false
        print("Fetched \(recommendedItems.count) random recommended items.")
    }

    // Removed the old fetchRecommendedItems() function that used Gemini API
}

// MARK: - GroceryListItemRow Helper View
struct GroceryListItemRow: View {
    let cartItem: CartItem

    var body: some View {
        HStack {

            VStack(alignment: .leading) {
                Text(cartItem.item.name)
                    .font(.body)
                    .foregroundColor(.white)
                Text("Aisle: \(cartItem.item.aisle)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("Qty: \(cartItem.quantity)")
                    .font(.caption)
                    .foregroundColor(Color.lumoGreen)
            }
            .padding(.leading)

            Spacer()
            Text("$\(cartItem.totalPrice, specifier: "%.2f")")
                .font(.body)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .background(Color.darkGrayBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - RecommendedItemCard View
struct RecommendedItemCard: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState // To add to cart

    var body: some View {
        HStack {
            Text(item.name)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Button(action: {
                appState.shoppingCart.addItem(item)
                print("Added recommended item: \(item.name) to cart.")
            }) {
                Image(systemName: "cart.badge.plus")
                    .foregroundColor(Color.lumoGreen)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color.darkGrayBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - ShareSheet Wrapper for UIActivityViewController
#if canImport(UIKit)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
// Fallback for macOS
struct ShareSheet: View {
    var activityItems: [Any]
    
    var body: some View {
        Text("Sharing not available on macOS")
    }
}
#endif


// MARK: - Preview Provider
struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
            .environmentObject(AppState()) // Provide AppState for preview
    }
}
